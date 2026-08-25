# Replacing Foundation's `XMLParser` with libxml2 — Implementation Plan

**Scope of this phase: the parser only.** `XMLNode`, `XMLElement`,
`XMLAttribute`, `XMLFormatter`, and everything under `AST/` and `Formatter/`
are untouched. The public API of `XMLParser` remains **exactly** as it stands
today.

Every mechanism this plan depends on was verified empirically before the plan
was written; measurements are marked ✅ and were taken on macOS 26.5.2, Apple
Swift 6.3.3, Xcode SDKs MacOSX26.5 / iPhoneOS26.5, libxml2 **2.9.13** (the
version shipped in *both* SDKs).

Companion document: [XMLNodeContent.md](XMLNodeContent.md), which catalogues
the Foundation limitations this migration exists to remove.

## Contents

- [1. Why](#1-why)
- [2. What must not change](#2-what-must-not-change)
- [3. Feasibility, verified](#3-feasibility-verified)
- [4. Packaging](#4-packaging)
- [5. Architecture](#5-architecture)
- [6. The five non-obvious mechanics](#6-the-five-non-obvious-mechanics)
- [7. File-by-file changes](#7-file-by-file-changes)
- [8. Behavior deltas](#8-behavior-deltas)
- [9. Decision points](#9-decision-points)
- [10. Test plan](#10-test-plan)
- [11. Risks](#11-risks)
- [12. Step-by-step task list](#12-step-by-step-task-list)

## 1. Why

`XMLParser`'s doc comment currently documents four limitations
(`Sources/XestiXML/Parser/XMLParser.swift:22-49`). All four are **Foundation
artifacts, not XML or libxml2 limitations**. Driving libxml2's SAX2 interface
directly removes two of them outright and makes the other two a matter of
choice:

| Documented limitation | Under libxml2 |
|---|---|
| Internal entity references silently dropped | ✅ Expands correctly — `A[&e;]B` → `A[EXPANDED]B` |
| External entity reference also eats the following text | ✅ Becomes a real, reported parse error instead of silent corruption |
| DTD-defaulted attributes indistinguishable from real ones | ✅ `nbDefaulted` identifies them exactly |
| Attribute namespace URI unavailable; name arrives prefixed | ✅ `startElementNs` supplies local name, prefix, and URI separately |

Secondary benefits: no `NSObject` delegate, no Objective-C bridging on the hot
path, and error handling that is per-parse rather than process-global.

## 2. What must not change

This is the acceptance contract. The following is the entire public surface of
the parser, and none of it may move:

```swift
public struct XMLParser<E: XMLElement, A: XMLAttribute> {
    public init()
    public func parse(_ data: Data) throws -> XMLNode<E, A>
}

extension XMLParser {
    public enum Error: EnhancedError, Sendable {
        case internalFailure
        case parseFailure((any EnhancedError)?, Int, Int)
        case unrecognizedAttribute(String, Int, Int)
        case unrecognizedElement(String, String?, Int, Int)
    }
}
```

Behaviorally, these must also hold, because tests and callers depend on them:

- Text is accumulated across adjacent character events and passed through
  `normalizedXMLWhitespace()` exactly once per text run
  (`XMLParser.Context.swift:87`).
- CDATA is merged into surrounding text, not distinguished
  (`XMLParserTests.parse_cdataContent`).
- Element identity is **local name + namespace URI**, with an empty URI
  normalized to `nil` via `nilIfEmpty` (`XMLParser.Context.swift:61,130`).
- `A(name:)` receives the **qualified** attribute name (`a:id`, not `id`) —
  see [§8.4](#84-attribute-names-stay-qualified).
- `xmlns` / `xmlns:*` declarations are never presented as attributes.
- An unrecognized element or attribute aborts the parse and throws
  `.unrecognizedElement` / `.unrecognizedAttribute` carrying line and column.
- All 17 tests in `Tests/XestiXMLTests/Parser/XMLParserTests.swift` pass
  unmodified.

## 3. Feasibility, verified

Every row below was measured, not inferred.

| Question | Result |
|---|---|
| Does `import libxml2` work from SPM with no target settings? | ✅ Yes — builds clean, zero flags, zero `unsafeFlags` |
| …on iOS device and simulator? | ✅ Typechecks for `arm64-apple-ios16.0` and `-simulator` |
| Is the module map present in all three SDKs? | ✅ macosx, iphoneos, iphonesimulator |
| Can Swift populate `xmlSAXHandler` with `@convention(c)` callbacks? | ✅ Yes |
| Can callbacks reach both our state *and* the parser context? | ✅ Via the `userData == ctxt` idiom + `_private` ([§6.1](#61-getting-both-pointers-into-every-callback)) |
| Namespaced attributes with URIs? | ✅ `a:id`→`urn:a`, `b:id`→`urn:b`, `plain`→`nil`, order preserved |
| DTD-defaulted attributes identifiable? | ✅ `nbAttr=1 nbDefaulted=1` |
| Internal entity expansion? | ✅ `A[EXPANDED]B` — **with no extra SAX handlers installed at all** |
| Abort mid-parse with line/column? | ✅ `xmlStopParser` + `xmlSAX2GetLineNumber/ColumnNumber` → `line=3 col=8` |
| Structured errors with code/line/column/message? | ✅ `serror` → `code=5 line=1 col=7 "Extra content at the end of the document"` |
| UTF-8 / UTF-16 BOM / UTF-16 declared / Latin-1 input? | ✅ All parse; callbacks always deliver UTF-8 |
| CDATA delivered separately? | ✅ `cdataBlock` |
| Can libxml2's stderr chatter be suppressed without losing errors? | ✅ `XML_PARSE_NOERROR\|XML_PARSE_NOWARNING` silences stderr, `serror` still fires |

## 4. Packaging

**`Package.swift` needs no changes at all.** The Apple SDKs ship
`usr/include/libxml2/module.modulemap`, so `import libxml2` resolves with no
`systemLibrary` target, no `pkgConfig`, and — critically — no `unsafeFlags`,
which would have barred XestiXML from being consumed as a tagged dependency.

Because the package enables `InternalImportsByDefault` and
`MemberImportVisibility`, each file that touches libxml2 must declare
`internal import libxml2` explicitly.

## 5. Architecture

### 5.1 The generic barrier

This is the one genuine structural problem, and it dictates the whole design.

`XMLParser.Context` is generic over `E` and `A`. libxml2 callbacks must be
`@convention(c)` function pointers, and **a C function pointer cannot be formed
from a closure that captures generic parameters**. The callbacks therefore
cannot mention `E` or `A`.

Solution: a **non-generic class at the C boundary**, with the generic work in a
subclass. `Unmanaged<SAXEventSink>` then round-trips through the void pointer
with no downcast.

```
  libxml2 (C)                 boundary                 generic Swift
  ───────────                 ────────                 ─────────────
  xmlSAXHandler  ──calls──▶  @convention(c) fns  ──▶  SAXEventSink (class)
                                                            △
                                                            │ overrides
                                                     XMLParser<E,A>.EventSink
                                                            │ wraps
                                                     XMLParser<E,A>.Context
```

`SAXEventSink` lives at file scope (**not** nested inside `XMLParser`, which
would make it generic too).

### 5.2 Target file layout

```
Sources/XestiXML/Parser/
    XMLParser.swift                     MODIFIED  — parse(_:) body + doc comment
    XMLParser.Error.swift               unchanged
    Internal/
        LibXMLError.swift               NEW  — EnhancedError wrapper for xmlError
        SAXEventSink.swift              NEW  — non-generic boundary base class
        SAXHandler.swift                NEW  — the @convention(c) callbacks
        SAXParser.swift                 NEW  — context lifecycle, feeding, teardown
        XMLParser.Context.swift         MODIFIED  — error entry points only
        XMLParser.EventSink.swift       NEW  — generic subclass bridging to Context
        XMLParser.Delegate.swift        DELETED
```

Net: one file deleted, five added, two modified. No file outside `Parser/`
changes.

### 5.3 Sketches

**`SAXEventSink.swift`** — the boundary type. Methods are no-ops here; the
subclass supplies behavior.

```swift
internal class SAXEventSink {
    internal var shouldAbort: Bool { false }

    internal func appendText(_ text: String) {}
    internal func endElement(_ name: String, _ uri: String?) {}
    internal func handleAbort(_ line: Int, _ column: Int) {}
    internal func handleError(_ error: LibXMLError) {}
    internal func startElement(_ name: String, _ uri: String?, _ attributes: [String: String]) {}
}
```

**`XMLParser.EventSink.swift`** — the generic subclass. Thin; all real logic
stays in the existing `Context`.

```swift
extension XMLParser {
    internal final class EventSink: SAXEventSink {
        internal private(set) var context = Context()

        override internal var shouldAbort: Bool { context.shouldAbort }

        override internal func appendText(_ text: String) {
            context.appendText(text)
        }

        override internal func startElement(_ name: String,
                                            _ uri: String?,
                                            _ attributes: [String: String]) {
            context.startElement(name, uri, attributes)
        }

        // … endElement, handleAbort, handleError likewise
    }
}
```

**`SAXHandler.swift`** — string helpers plus the callbacks.

```swift
internal import libxml2

private func _resolve(_ ctx: UnsafeMutableRawPointer?) -> (SAXEventSink, xmlParserCtxtPtr) {
    let ctxt = xmlParserCtxtPtr(OpaquePointer(ctx!))

    return (Unmanaged<SAXEventSink>.fromOpaque(ctxt.pointee._private).takeUnretainedValue(),
            ctxt)
}

private func _string(_ pointer: UnsafePointer<xmlChar>?) -> String? {
    pointer.map { String(cString: $0) }
}

private func _string(_ pointer: UnsafePointer<xmlChar>?,
                     _ length: Int32) -> String {
    guard let pointer, length > 0
    else { return "" }

    return String(decoding: UnsafeBufferPointer(start: pointer, count: Int(length)),
                  as: UTF8.self)
}

// Attribute values are delimited by a start/end pair and are NOT NUL-terminated.
private func _string(from start: UnsafePointer<xmlChar>?,
                     to end: UnsafePointer<xmlChar>?) -> String {
    guard let start, let end, end > start
    else { return "" }

    return String(decoding: UnsafeBufferPointer(start: start, count: end - start),
                  as: UTF8.self)
}

internal let saxStartElementNs: startElementNsSAX2Func = { ctx, localName, _, uri,
                                                           _, _, attrCount, defaultedCount, attrs in
    let (sink, ctxt) = _resolve(ctx)

    var attributes: [String: String] = [:]

    if let attrs {
        for index in 0..<Int(attrCount) {
            let base = index * 5
            let local = _string(attrs[base]) ?? ""
            let name = _string(attrs[base + 1]).map { "\($0):\(local)" } ?? local

            attributes[name] = _string(from: attrs[base + 3], to: attrs[base + 4])
        }
    }

    sink.startElement(_string(localName) ?? "", _string(uri), attributes)

    if sink.shouldAbort {
        sink.handleAbort(Int(xmlSAX2GetLineNumber(ctx)),
                         Int(xmlSAX2GetColumnNumber(ctx)))

        xmlStopParser(ctxt)
    }
}

internal let saxCharacters: charactersSAXFunc = { ctx, chars, length in
    _resolve(ctx).0.appendText(_string(chars, length))
}

internal let saxCdataBlock: cdataBlockSAXFunc = { ctx, chars, length in
    _resolve(ctx).0.appendText(_string(chars, length))
}

internal let saxEndElementNs: endElementNsSAX2Func = { ctx, localName, _, uri in
    _resolve(ctx).0.endElement(_string(localName) ?? "", _string(uri))
}

internal let saxError: xmlStructuredErrorFunc = { ctx, error in
    guard let error
    else { return }

    _resolve(ctx).0.handleError(LibXMLError(error.pointee))
}
```

`defaultedCount` is deliberately named and ignored — see
[§9.2](#92-should-dtd-defaulted-attributes-still-be-injected).

**`SAXParser.swift`** — the driver.

```swift
internal import Foundation
internal import libxml2

// Swift initializes a global `let` exactly once, thread-safely.
private let isInitialized: Bool = {
    xmlInitParser()

    return true
}()

private let options = Int32(XML_PARSE_NONET.rawValue)
                    | Int32(XML_PARSE_NOERROR.rawValue)
                    | Int32(XML_PARSE_NOWARNING.rawValue)

internal func saxParse(_ data: Data,
                       _ sink: SAXEventSink) -> Bool {
    _ = _initialized

    var handler = xmlSAXHandler()

    handler.initialized = XML_SAX2_MAGIC
    handler.startElementNs = saxStartElementNs
    handler.endElementNs = saxEndElementNs
    handler.characters = saxCharacters
    handler.cdataBlock = saxCdataBlock
    handler.serror = saxError

    // The pointer must stay valid for the whole parse, so the entire parse runs
    // *inside* withUnsafeMutablePointer rather than just the context creation.
    return withUnsafeMutablePointer(to: &handler) { handlerPtr in
        // NULL userData => libxml2 sets ctxt->userData = ctxt (see §6.1).
        guard let ctxt = xmlCreatePushParserCtxt(handlerPtr, nil, nil, 0, nil)
        else { return false }

        defer { xmlFreeParserCtxt(ctxt) }

        ctxt.pointee._private = Unmanaged.passUnretained(sink).toOpaque()

        xmlCtxtUseOptions(ctxt, options)

        return withExtendedLifetime(sink) {
            data.withUnsafeBytes { raw in
                if let base = raw.baseAddress, !raw.isEmpty {
                    _ = xmlParseChunk(ctxt,
                                      base.assumingMemoryBound(to: CChar.self),
                                      Int32(raw.count),
                                      0)
                }

                _ = xmlParseChunk(ctxt, nil, 0, 1)
            }

            return ctxt.pointee.wellFormed != 0 && !sink.shouldAbort
        }
    }
}
```

**`XMLParser.parse(_:)`** — the whole public method becomes:

```swift
public func parse(_ data: Data) throws -> XMLNode<E, A> {
    let sink = EventSink()

    guard saxParse(data, sink)
    else { throw sink.context.result.failure ?? Error.internalFailure }

    return try sink.context.result.get()
}
```

## 6. The five non-obvious mechanics

Each of these will silently do the wrong thing if guessed at. All were verified.

### 6.1 Getting both pointers into every callback

A callback needs *two* things: our sink (to record events) and the
`xmlParserCtxt` (for line numbers and `xmlStopParser`). It receives one `void *`.

Pass **`NULL` as `user_data`** to `xmlCreatePushParserCtxt`. libxml2 then sets
`ctxt->userData = ctxt`, so every SAX2 callback receives the parser context
itself. Our sink rides in the context's `_private` field. ✅ Verified
`ctxt.pointee.userData == UnsafeMutableRawPointer(ctxt)`.

### 6.2 Attribute values are not NUL-terminated

The `attributes` array is a flat run of 5-tuples — `localname, prefix, URI,
value_start, value_end`. `value_start` points into the parser's buffer and is
**not** NUL-terminated; the value is the half-open range `[start, end)`. Calling
`String(cString:)` on it reads past the value into the rest of the document.
This is the sharpest footgun in the whole migration; hence the distinct
`_string(from:to:)` helper.

### 6.3 Character data arrives in arbitrary chunks

libxml2 splits text at boundaries that are not semantically meaningful — ✅
`<root>héllo</root>` arrives as `"h"` then `"éllo"`. Entity expansions arrive as
separate runs too (`"before "`, `"EXPANDED"`, `" after"`). Accumulation before
normalization is mandatory. The existing `Context.pendingText` /
`flushText()` design already does exactly this and needs no change.

### 6.4 Aborting does not raise an error

`xmlStopParser` yields `rc=-1` and `disableSAX=1` but leaves **`wellFormed=1`**,
and it does **not** invoke the `serror` handler. So:

- Abort must be detected by our own flag, never by `wellFormed`.
- Line and column must be captured *at abort time* inside the callback, via
  `xmlSAX2GetLineNumber`/`xmlSAX2GetColumnNumber`.

This is why `saxParse` returns `wellFormed != 0 && !sink.shouldAbort`.

### 6.5 Install only our own handlers

Assigning libxml2's own defaults into unrelated slots is actively harmful.
Setting `entityDecl = xmlSAX2EntityDecl` without also building a document
produced ✅ `error : xmlAddDocEntity: document is NULL` on **stderr**, and
triggered an external-entity load attempt that a bare handler never makes.

Internal entity expansion needs **no handler at all** — libxml2 does it
internally. ✅ Confirmed with a handler carrying only `characters` and
`startElementNs`.

Corollary: do not set `XML_PARSE_NOBLANKS` (it aliases `ignorableWhitespace` onto
`characters`), `XML_PARSE_NOCDATA` (it NULLs `cdataBlock`), or `XML_PARSE_HUGE`
(it lifts the entity-expansion limits that protect against billion-laughs).

## 7. File-by-file changes

### `Internal/LibXMLError.swift` (new)

`XMLParser.Error.parseFailure` carries `(any EnhancedError)?`. Today that slot
holds Foundation's `NSError` (which conforms via
`XestiTools/Extensions/Foundation/NSError+Extensions.swift`). It needs a
replacement:

```swift
internal import libxml2

private import XestiTools

internal struct LibXMLError: EnhancedError, Sendable {
    internal let code: Int32
    internal let column: Int
    internal let line: Int
    internal let text: String

    internal init(_ error: xmlError) {
        self.code = error.code
        self.column = Int(error.int2)
        self.line = Int(error.line)
        self.text = error.message.map { String(cString: $0) }?
                                 .trimmingCharacters(in: .newlines) ?? ""
    }

    internal var message: String {
        "libxml2 error \(code): \(text)"
    }
}
```

Note `int2` is libxml2's column field — a struct-field convention, not an
obviously named API. It is exercised by the tests in [§10](#10-test-plan).

### `Internal/XMLParser.Context.swift` (modified)

Only the error path changes. Drop `internal import Foundation` and the
`BaseXMLParser` typealias, and replace `handleParseError(_:_:)` with two
entry points that do not mention Foundation:

```swift
internal mutating func handleAbort(_ line: Int,
                                   _ column: Int) {
    if let attr = unrecognizedAttribute {
        result = .failure(.unrecognizedAttribute(attr, line, column))
    } else if let (name, uri) = unrecognizedElement {
        result = .failure(.unrecognizedElement(name, uri, line, column))
    } else {
        result = .failure(.parseFailure(nil, line, column))
    }
}

internal mutating func handleError(_ error: LibXMLError) {
    result = .failure(.parseFailure(error, error.line, error.column))
}
```

`appendText`, `startElement`, `endElement`, and `flushText` are **unchanged** —
the whole tree-building core survives the migration intact. That is the main
reason this is tractable.

One ordering subtlety: libxml2 can report several errors for one document.
`handleError` overwrites `result` each time, so the *last* error wins, whereas
Foundation reported the first. Guard it with `if case .success = result` — or
better, record only when no failure is already latched, so an
`unrecognizedElement` abort is never masked by a trailing syntax error.

### `Parser/XMLParser.swift` (modified)

Body of `parse(_:)` as in [§5.3](#53-sketches), plus the doc comment:

- "wraps the event-driven XML parser provided in `Foundation`" → libxml2.
- **Delete** limitation bullets 1 and 2 (`XMLParser.swift:26-37`) — the entity
  bugs are gone.
- Bullets 3 and 4 stay or go per [§9](#9-decision-points).
- Add a note that external DTDs and external entities are never fetched
  (`XML_PARSE_NONET`, and `XML_PARSE_DTDLOAD` deliberately unset).

### `Internal/XMLParser.Delegate.swift` (deleted)

Its 11 commented-out delegate stubs are superseded by
[XMLNodeContent.md](XMLNodeContent.md), which records what each one actually
yields. Nothing is lost by deleting the file.

## 8. Behavior deltas

The public API is identical, but four observable behaviors change. All four are
improvements; all four could surprise an existing caller.

### 8.1 Internal entities now expand (bug fix)

`<!DOCTYPE root [<!ENTITY e "EXPANDED">]><root>A[&e;]B</root>`

- Foundation: `A[` — reference *and* the following text silently dropped.
- libxml2: ✅ `A[EXPANDED]B`.

### 8.2 Undeclared and unresolvable entities now fail loudly

`<root>A[&nope;]B</root>`

- Foundation: `parse()` returns `true`, text is `A[`. Silent corruption.
- libxml2: ✅ `wellFormed=0`, error 26 `Entity 'nope' not defined` → throws
  `.parseFailure`.

Same for an entity declared `SYSTEM`, since external content is never fetched.
**This is the only delta that turns a previous success into a failure.** It is
the correct behavior — the alternative was returning a truncated document as if
it were complete — but any caller relying on lenient parsing of such documents
will now see a thrown error. Setting `XML_PARSE_NOENT` would instead skip them
silently (✅ yields `A[]B`); this plan recommends against that, because silence
is what caused the problem in the first place.

### 8.3 Error text and column numbers change

`.parseFailure`'s cause becomes `LibXMLError` rather than `NSError`, so
`message`, `code`, and `domain` all read differently, and columns may differ by
a character or two for the same defect. Nothing in the test suite asserts on
either — `XMLParserErrorTests` constructs `Error` values directly and only
checks `message` substring content — so no test changes are required.

### 8.4 Attribute names stay qualified

libxml2 hands over local name, prefix, and URI as three separate fields; the
sketch in [§5.3](#53-sketches) **re-joins prefix and local name** into `a:id`
before calling `A(name:)`. That is deliberate: it preserves today's exact
behavior for every existing `XMLAttribute` conformer. Doing anything smarter
would change `XMLAttribute` semantics, which is out of scope for this phase —
see [§9.1](#91-should-attributes-gain-namespace-uris).

## 9. Decision points

These need an answer before coding starts. All three are recommended as
**"preserve current behavior now, revisit later"**, so that this phase is a pure
parser swap and any semantic change lands as its own reviewable step.

### 9.1 Should attributes gain namespace URIs?

libxml2 supplies them; `XMLAttribute` has no `uri` and cannot carry them without
a protocol change — a **public API change**, excluded by the brief.
**Recommendation: no.** Keep qualified names. Revisit alongside any
`XMLNode.Content` expansion.

### 9.2 Should DTD-defaulted attributes still be injected?

`nbDefaulted` tells us exactly which trailing attributes libxml2 synthesized
from `<!ATTLIST>`; skipping them is a one-line change
(`for index in 0..<Int(attrCount - defaultedCount)`). Doing so would fix the
spurious `unrecognizedAttribute` described in `XMLParser.swift:39-43`.
**Recommendation: keep injecting for now** (status quo), and delete the doc
bullet only if and when this changes.

### 9.3 Should attribute order be preserved?

libxml2 preserves it; `Context.pendingAttributes` is `[A: String]`, unordered by
construction. The information is unusable without an AST change.
**Recommendation: no.** Noted so it is not mistaken for an oversight.

## 10. Test plan

### Regression gate

The existing suite — 207 tests across 13 suites, `make lint` clean over 32 files
— must pass **unmodified**. The 17 tests in `XMLParserTests` are the real gate.

### New tests (`Tests/XestiXMLTests/Parser/XMLParserTests.swift`)

Behavior now worth asserting because it is newly correct or newly relied upon:

| Test | Input | Expectation |
|---|---|---|
| `parse_internalEntityExpanded` | `<!DOCTYPE root [<!ENTITY e "X">]><root>A&e;B</root>` | value `AXB` |
| `parse_predefinedEntity` | `<root>a &amp; b</root>` | value `a & b` |
| `parse_numericCharacterReference` | `<root>&#65;</root>` | value `A` |
| `parse_undeclaredEntityThrows` | `<root>&nope;</root>` | throws `.parseFailure` |
| `parse_externalEntityThrows` | entity declared `SYSTEM` | throws; **no network access** |
| `parse_namespacedAttributes` | `<root xmlns:a="urn:a" a:id="1" id="2"/>` | keys `a:id` and `id`, distinct |
| `parse_defaultNamespaceOnElement` | `<root xmlns="urn:d"/>` | element `uri == "urn:d"` |
| `parse_xmlnsNotAnAttribute` | `<root xmlns:a="urn:a"/>` | attributes empty |
| `parse_utf16WithBOM` | UTF-16LE + BOM | parses; text correct |
| `parse_utf16Declared` | `encoding="UTF-16"` | parses |
| `parse_latin1Declared` | `encoding="ISO-8859-1"` | non-ASCII preserved |
| `parse_textSplitAcrossChunks` | text with non-ASCII mid-run | single normalized text node |
| `parse_cdataAdjacentToText` | `<root>a<![CDATA[<b>]]>c</root>` | value `a<b>c` |
| `parse_emptyData` | `Data()` | throws |
| `parse_abortReportsPosition` | unknown element on line 3 | `.unrecognizedElement` with `line == 3` |
| `parse_deeplyNested` | 500 levels | parses; no stack overflow |
| `parse_repeatedParsesAreIndependent` | same parser, 3 documents | identical results, no cross-talk |

### Sanitizers

Mandatory for C interop, and not currently part of `make test`:

```
swift test --sanitize=address
swift test --sanitize=thread          # confirms parse(_:) is reentrant
```

Consider adding a `make test-sanitize` target.

### Platform verification

Because the whole analysis was measured on macOS, the iOS build must be proven
before merge — at minimum a compile for `arm64-apple-ios16.0`, and ideally the
suite run on a simulator.

## 11. Risks

| Risk | Severity | Mitigation |
|---|---|---|
| Reading past a non-NUL-terminated attribute value | **High** — silent memory disclosure into parsed output | Single `_string(from:to:)` helper; never `String(cString:)` on `attrs[base+3]`; ASAN in CI |
| Sink deallocated while libxml2 holds its pointer | **High** — use-after-free | `Unmanaged.passUnretained` + `withExtendedLifetime`; sink is owned by the `parse(_:)` stack frame for the whole call |
| libxml2 version skew across the iOS 16 → 26 support range | Medium | Only SAX2 API used, stable since 2.6; fields touched (`_private`, `userData`, `wellFormed`) are public struct members. Both current SDKs ship 2.9.13 ✅ |
| `xmlError.int2`-as-column is a convention, not a named API | Low | Asserted by `parse_abortReportsPosition` and friends |
| stderr chatter leaking into host apps' logs | Low | `XML_PARSE_NOERROR\|XML_PARSE_NOWARNING` ✅ verified to silence stderr while `serror` still fires |
| Swift cannot implement libxml2's variadic `warning`/`error` slots | Low | Not needed — `serror` is non-variadic and supersedes both |
| Entity-expansion DoS (billion laughs) | Low | Default limits retained; `XML_PARSE_HUGE` deliberately unset |
| XXE | Low | `XML_PARSE_NONET` set, `XML_PARSE_DTDLOAD` unset — external DTDs and entities are never fetched. Stricter than Foundation, which relied on undocumented inertness |

Deliberately **not** a risk: process-global libxml2 error handlers. This design
uses per-context `serror` only, so a host app's own libxml2 usage is unaffected.

## 12. Step-by-step task list

Each step ends at a compiling, testable checkpoint.

1. **Spike, throwaway.** Reproduce the verified probe inside the package as a
   scratch target: parse a fixture and print events. Confirms SPM, module map,
   and callbacks in the *real* build configuration (`swiftLanguageModes: [.v6]`,
   `defaultIsolation(nil)`, upcoming features on). Delete afterward.
2. **`LibXMLError.swift`.** Standalone; unit-testable by constructing an
   `xmlError` directly.
3. **`SAXEventSink.swift` + `XMLParser.EventSink.swift`.** Pure Swift, no C.
   Add `handleAbort`/`handleError` to `Context` in the same step; both old and
   new parsers can coexist here, so the suite stays green.
4. **`SAXHandler.swift`.** The callbacks. Highest-risk file — review
   [§6.2](#62-attribute-values-are-not-nul-terminated) line by line.
5. **`SAXParser.swift`.** The driver.
6. **Switch `parse(_:)` over** and delete `XMLParser.Delegate.swift`. Run the
   existing suite; expect only entity-related behavior to differ.
7. **Add the new tests** from [§10](#10-test-plan).
8. **Run sanitizers**, then `make lint` and `make test`.
9. **Update the `XMLParser` doc comment** per [§7](#7-file-by-file-changes).
10. **Verify the iOS build.**
11. **Update [XMLNodeContent.md](XMLNodeContent.md)** — its Foundation-limitation
    findings become historical background, and the "Recommendation" tiers should
    be reconsidered now that DOCTYPE, entity boundaries, and attribute
    namespaces are all reachable.

Steps 1–5 are additive and cannot break anything. Step 6 is the single
irreversible commit; everything before it can be landed and reviewed
independently.
