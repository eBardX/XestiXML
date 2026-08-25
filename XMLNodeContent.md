# Expanding `XMLNode.Content` to the limit of libxml2

A design note exploring how much of an XML document `XMLNode` *could*
represent, given what libxml2's SAX2 interface actually exposes to
`XMLParser`. This is an analysis, not a commitment to implement.

Every claim below was **verified empirically** with a throwaway probe that
installs *every* handler slot in `xmlSAXHandler` and logs each invocation (see
[Method](#method)); measured on macOS 26.5.2, Apple Swift 6.3.3,
`arm64-apple-macosx26.0`, libxml2 **2.9.13** (the version shipped in both the
macOS and iOS SDKs).

The headline is that the parser installed five of libxml2's thirty-odd handler
slots, and that nearly everything `XMLNode.Content` could not represent was
sitting in the slots left empty — including two things the parser already
received and discarded without any new handler at all.

Tiers 0, 1, 2, and 3 of the [Recommendation](#recommendation) have since been
implemented; see [What was built](#what-was-built). Tiers 4, 5, and 6 are
closed, most likely permanently. Everything else below stands as analysis.

Companion document: [Libxml2Migration.md](Libxml2Migration.md).

## Contents

- [Background](#background)
- [Method](#method)
- [What we already receive and throw away](#what-we-already-receive-and-throw-away)
- [What one more handler buys](#what-one-more-handler-buys)
- [The DTD, at full fidelity](#the-dtd-at-full-fidelity)
- [Entity boundaries](#entity-boundaries)
- [What is still genuinely out of reach](#what-is-still-genuinely-out-of-reach)
- [The error path: two defects, since fixed](#the-error-path-two-defects-since-fixed)
- [The maximal `Content`](#the-maximal-content)
- [Cost of each addition](#cost-of-each-addition)
- [Recommendation](#recommendation)
- [What was built](#what-was-built)
- [Remaining open questions](#remaining-open-questions)

## Background

`XMLNode.Content` (`Sources/XestiXML/AST/Internal/XMLNode.Content.swift`)
currently has two cases:

```swift
case element(E, [A: String], [XMLNode])
case text(String)
```

`XMLParser` deliberately throws away everything else — its doc comment says so
explicitly: "only elements, with any associated attributes, and text are
represented … Other XML items (such as document type declarations, processing
instructions, comments, and ignorable whitespace characters) are ignored. CDATA
blocks are converted to text."

That discarding happens in two places, and it is worth separating them:

1. **Handlers we never install.** `saxParse` populates exactly five slots —
   `startElementNs`, `endElementNs`, `characters`, `cdataBlock`, `serror`
   (`SAXParser.swift`). Every other slot is left NULL, so libxml2 has nothing
   to call.
2. **Arguments we ignore.** `saxStartElementNs` (`SAXHandler.swift`) binds four
   of its nine parameters to `_`.

The question here: **with the parse options unchanged — `XML_PARSE_NONET` set,
`XML_PARSE_NOENT` and `XML_PARSE_DTDLOAD` deliberately unset — what is the
maximum information a `Content` enum could represent, and what does each
increment cost?**

## Method

A probe implementing every `xmlSAXHandler` slot Swift can express (all but the
variadic `warning`/`error`/`fatalError` trio, which `serror` supersedes), run
over a kitchen-sink document: an internal DTD subset containing all six
declaration kinds, prolog and epilog comments and PIs, comments and PIs *inside*
the internal subset, a CDATA section, element-only content models with
inter-element whitespace, colliding namespaced attributes (`a:id` and `b:id`),
a prefix redeclared on a descendant, an unused namespace declaration, nested and
repeated entity references, and an entity whose replacement text is markup.

Supporting documents covered: a MusicXML-style external `PUBLIC` DOCTYPE with no
internal subset; UTF-16LE with BOM; a declared `ISO-8859-1` encoding; every
combination of XML declaration pseudo-attributes; a billion-laughs bomb; and a
document invalid against its own DTD, parsed both with and without
`XML_PARSE_DTDVALID`.

## What we already receive and throw away

These need **no new handler**. libxml2 is passing them to
`saxStartElementNs` right now, and the callback discards them.

### Namespace declarations, in document order

`startElementNs`'s fifth and sixth parameters are `nb_namespaces` and a flat
array of `(prefix, URI)` pairs — the declarations written *on that element*,
already scoped. Measured against

```xml
<r xmlns:z="urn:z" xmlns:m="urn:m" xmlns="urn:d" xmlns:a="urn:a">
  <z:k xmlns:z="urn:z2" xmlns="urn:d2"><z:deep/></z:k>
</r>
```

| Element | Reported declarations | Element URI |
|---|---|---|
| `r` | `z=urn:z`, `m=urn:m`, `(nil)=urn:d`, `a=urn:a` | `urn:d` |
| `k` | `z=urn:z2`, `(nil)=urn:d2` | `urn:z2` |
| `deep` | *(none)* | `urn:z2` |

Four properties, all confirmed:

- **Document order is preserved exactly** — including the default declaration
  sitting third, where the source put it. A default namespace is reported with
  a `nil` prefix.
- **Declarations are attached to the declaring element**, not inherited, so
  `deep` correctly reports none while still resolving to `urn:z2`.
- **Redeclaration on a descendant nests correctly**, for both prefixed and
  default namespaces.
- **Unused declarations survive.** `xmlns:m` and `xmlns:unused`, bound to URIs
  no name in the document references, were both reported.

This is exactly the information `XMLFormatter` currently *synthesizes* rather
than records (see [Cost of each addition](#cost-of-each-addition)), and it is
already in the callback's hands.

### Attribute prefixes, namespace URIs, and DTD-defaulted flags

The `attributes` array is a flat run of 5-tuples — `localname, prefix, URI,
value_start, value_end`. The callback uses fields 0, 1, 3, and 4, re-joining
prefix and local name into a qualified string, and ignores field 2 entirely.

For `<child a:id="1" id="2" plain="3">` under `xmlns:a="urn:a"`:

| local | prefix | URI | value |
|---|---|---|---|
| `id` | `a` | `urn:a` | `1` |
| `id` | *(nil)* | *(nil)* | `2` |
| `plain` | *(nil)* | *(nil)* | `3` |

So the attribute namespace URI is available for the asking; only
`XMLAttribute`'s lack of a `uri` property keeps it out. **Attribute order is
also preserved** in the array, and `xmlns`/`xmlns:*` never appear in it.

`nb_defaulted` (the callback's eighth parameter, also bound to `_`) counts the
attributes libxml2 synthesized from `<!ATTLIST>` defaults, and those are always
the **trailing** entries. Measured with `<!ATTLIST r d CDATA "DFLT" e CDATA
"DFLT2">` and `<r z="written" a="also"/>`: `nbAttr=4 nbDefaulted=2`, in the
order `z`, `a`, `d`, `e`. Suppressing defaulted attributes is therefore a
one-line change (`0..<Int(attrCount - defaultedCount)`), and distinguishing them
while keeping them is barely harder.

### Source positions on every event

`xmlSAX2GetLineNumber`/`xmlSAX2GetColumnNumber` work in any callback, not just
at abort time. If `XMLNode` ever wants to carry provenance, the plumbing is
already there.

One caveat, measured: **positions inside entity replacement text are positions
within the entity, not the document.** Text expanded from `&a;` reports line 1
column 4 — the offset into the entity's own value. A position model must either
ignore events arriving inside an expansion or track the entity depth.

## What one more handler buys

Each row below is one assignment in `saxParse`, and each was confirmed firing.

| Handler | Payload | Buys |
|---|---|---|
| `internalSubset` | name, publicID, systemID | The **entire DOCTYPE header** |
| `comment` | text | Comments, everywhere they can legally appear |
| `processingInstruction` | target, data | PIs, everywhere they can legally appear |
| `reference` | entity name | Entity boundaries — see [below](#entity-boundaries) |
| `elementDecl` | name, type, content model | Real content models |
| `attributeDecl` | element, name, type, default kind, default value, enumeration | Real attribute types |
| `entityDecl` | name, type, publicID, systemID, replacement text | Entity declarations |
| `unparsedEntityDecl` | name, publicID, systemID, notation | Unparsed entities |
| `notationDecl` | name, publicID, systemID | Notations |

### The DOCTYPE is one handler, not a prolog scan

`internalSubset` fires once, before any declaration, and carries the complete
DOCTYPE header — **including for a DOCTYPE with an external ID and no internal
subset**, which is the case that matters. Measured against a MusicXML 4.0
header:

| Argument | Value |
|---|---|
| `name` | `score-partwise` |
| `ExternalID` | `-//Recordare//DTD MusicXML 4.0 Partwise//EN` |
| `SystemID` | `http://www.musicxml.org/dtds/partwise.dtd` |

Nothing was fetched — the parse completed in single-digit milliseconds with no
network access, because `XML_PARSE_DTDLOAD` is unset. This matters concretely
for document types *identified* by their DOCTYPE: a read-modify-write of a
MusicXML score through `XestiXML` today produces output that is well-formed XML
but no longer announces itself as MusicXML, which some consumers reject.

Note that `externalSubset` fires immediately afterward with **the same three
values**, so installing both would double-report the DOCTYPE. Install
`internalSubset` only.

### The XML declaration needs no handler at all

`version`, `encoding`, and `standalone` are fields on `xmlParserCtxt`, readable
after `xmlParseChunk` returns — one place, `saxParse`, with no callback and no
prolog scanning:

| Field | Meaning | Measured |
|---|---|---|
| `ctxt->version` | declared version | `1.0`, `1.1` — but see below |
| `ctxt->encoding` | **declared** encoding, `NULL` if absent | `UTF-8`, `ISO-8859-1`, `NULL` |
| `ctxt->standalone` | see table | `1` / `0` / `-1` / `-2` |

`standalone` is a four-way signal, and it is *better* than anything Foundation
offered — it distinguishes an absent declaration from an absent attribute:

| Value | Meaning |
|---|---|
| `1` | `standalone="yes"` |
| `0` | `standalone="no"` |
| `-1` | no XML declaration at all |
| `-2` | XML declaration present, no `standalone` pseudo-attribute |

Two cautions. **`ctxt->version` defaults to `1.0` when there is no declaration
at all**, so it cannot be used to detect one; `standalone == -1` is the reliable
test. And **`ctxt->encoding` reports only the *declared* encoding** — a UTF-16LE
document detected by its BOM parses correctly but reports `NULL`, since nothing
was declared. For round-tripping, the declared value is the one you want
anyway.

**XML 1.1 is not supported.** `<?xml version="1.1"?>` produces a warning-level
diagnostic (code 97, `Unsupported version '1.1'`), after which libxml2 parses
the document as 1.0. It is worth a line in `XMLParser`'s doc comment
independently of anything here — and it is what exposed the defect in
[The error path: two defects, since fixed](#the-error-path-two-defects-since-fixed).

### Comments and PIs, and telling them apart

Both handlers fire in all four positions comments and PIs can legally occupy,
delivered in document order:

- **Prolog** — before `internalSubset`, and after it too.
- **Inside the internal DTD subset** — confirmed; a comment and a PI written
  between declarations arrived through the same two handlers.
- **Element content** — interleaved with `characters` in the right places.
- **Epilog** — between the root's `endElementNs` and `endDocument`.

The important consequence: **the events carry no positional marker.** Prolog,
subset, content, and epilog items are indistinguishable at the callback, so a
consumer must track its own state — whether `internalSubset` has fired, whether
the root has opened, whether it has closed. That is trivial to do, but it has
to be done deliberately, and it is an argument for the document-level wrapper
in [The maximal `Content`](#the-maximal-content).

Also measured: **PI `data` is `NULL` when absent** (`<?epilog-pi?>`), and
pseudo-attribute PIs such as `<?xml-stylesheet href="a.xsl" type="text/xsl"?>`
arrive with `data` as the raw, unparsed string `href="a.xsl" type="text/xsl"`.

### `ignorableWhitespace` never fires

Confirmed across every configuration tried, **including with element-only
content models declared in an internal subset, and including with
`XML_PARSE_DTDVALID` set**. Inter-element whitespace arrived through
`characters` in every run. There is no reason to model a `.whitespace` case.

(The reason is structural: libxml2 routes whitespace to `ignorableWhitespace`
only when it has element-content validity information for the current element,
which requires the tree-building path this parser does not use.)

### Whitespace in the epilog

`<root/>   \n\t  ` produces no callback whatsoever between `endElementNs` and
`endDocument` — neither `characters` nor `ignorableWhitespace`. Trailing
whitespace is unrecoverable, which is harmless: it is the one thing in the
epilog nobody round-trips.

## The DTD, at full fidelity

This is where the analysis changes most sharply, and it is worth stating
plainly: **libxml2's declaration handlers deliver complete content models and
complete attribute types.** Measured from

```xml
<!ELEMENT root (child+)>
<!ELEMENT child (#PCDATA)>
<!ATTLIST child kind (a|b|c) "a"
                id ID #IMPLIED>
<!ENTITY e "EXPANDED">
<!ENTITY pic SYSTEM "pic.gif" NDATA gif>
<!NOTATION gif PUBLIC "-//gif//EN" "gif.dtd">
```

| Callback | Reported |
|---|---|
| `elementDecl` | `root`, type 4 (`ELEMENT`), model `(child)+` |
| `elementDecl` | `child`, type 3 (`MIXED`), model `(#PCDATA)` |
| `attributeDecl` | elem `child`, name `kind`, type 9 (`ENUMERATION`), default kind 1 (`NONE`), default value `a`, enumeration `[a, b, c]` |
| `attributeDecl` | elem `child`, name `id`, type 2 (`ID`), default kind 3 (`IMPLIED`), no default |
| `entityDecl` | `e`, type 1 (`INTERNAL_GENERAL`), content `EXPANDED` |
| `unparsedEntityDecl` | `pic`, systemID `pic.gif`, notation `gif` |
| `notationDecl` | `gif`, publicID `-//gif//EN`, systemID `gif.dtd` |

The content model arrives as an `xmlElementContentPtr` tree, not a string;
`xmlSnprintfElementContent` serializes it back to XML syntax, which is what the
`model` column above shows. The integer codes are the standard `xmlElementTypeVal`,
`xmlAttributeType`, and `xmlAttributeDefault` enumerations, so a Swift model can
be exhaustive rather than stringly-typed.

Every one of these is round-trippable. The DTD internal subset could be
re-serialized essentially byte-for-byte, modulo whitespace and the parenthesizing
`xmlSnprintfElementContent` chooses.

That said, **fidelity is not the same as demand.** Nothing in this package uses
DTDs, no external subset is ever loaded, and a faithfully preserved internal
subset would be inert data carried through the tree. See
[Recommendation](#recommendation).

### DTD validation is not available in this design

`XML_PARSE_DTDVALID` was tried, both with and without `XML_PARSE_NOERROR`,
against a document explicitly invalid against its own internal subset
(`<!ELEMENT root (child)*>` with a `<bogus/>` child). Result: **no validity
error was reported, and `ctxt->valid` stayed `1`.**

This is not a bug to work around. libxml2's validator needs `ctxt->myDoc`,
which is only built when the tree-building SAX2 defaults are installed —
exactly what this parser replaces. Streaming DTD validation would require
either building the document tree or switching to `xmlTextReader`. Both are
much larger changes than anything else in this note, and neither is motivated
by any current requirement.

## Entity boundaries

Internal entity references expand correctly in element content today, with no
handler installed. The `reference` handler makes the *boundaries* of those
expansions visible, which is what a byte-faithful round trip would need.

Its behavior is unusual enough to be worth spelling out. Given

```xml
<!ENTITY a "AAA">
<!ENTITY b "&a;-BBB">
<!ENTITY m "<kid>K</kid>">
…
<r>x&a;y&a;z&b;w&m;v</r>
```

the event sequence is:

```
characters "x"
characters "AAA"      ← expansion
reference  a          ← fires AFTER the content it produced
characters "y"
characters "AAA"
reference  a
characters "z"
characters "AAA"      ← inner expansion of &a; within &b;
reference  a          ← nested reference, innermost first
characters "-BBB"
reference  b
characters "w"
start kid / characters "K" / end kid     ← entity replacement text may be markup
reference  m
characters "v"
```

Three things follow:

1. **`reference` is a closing delimiter, not an opening one.** It fires *after*
   the events its expansion produced. Reconstructing `&a;` means buffering and
   retroactively wrapping, not switching modes on entry.
2. **References nest**, innermost first, with no depth marker on the event.
   Tracking depth is the consumer's job.
3. **Entity replacement text can be arbitrary markup**, so an entity boundary
   does not align with any node boundary — `&m;` spans a whole element. A
   `.entityReference(String)` leaf case therefore cannot represent the general
   case; only a wrapper node with children can.

Critically, **installing `reference` does not disable expansion.** Both were
delivered in every run. The handler is purely additive, which is not obvious
from libxml2's documentation and is the single most useful thing verified in
this section.

### Attribute values are the one place entities do not expand

Measured with `<!ENTITY a "AAA">` and `<r p="&a;" q="&amp;" s="&#65;"
t="&#38;#65;"/>`:

| Written | Delivered |
|---|---|
| `&a;` | `&a;` — literal, unexpanded |
| `&amp;` | `&#38;` |
| `&#65;` | `A` |
| `&#38;#65;` | `&#38;#65;` |

So character and predefined references *are* resolved; general entity
references are not. Installing a `getEntity` handler was tried and **changed
nothing** — it fires (three times, for the same entity) but the attribute value
still arrives literal. The only lever that would change this is
`XML_PARSE_NOENT`, which also makes libxml2 fetch external entities from the
file system, and must stay unset.

The last two rows also confirm the existing `_attributeValue` unescaping
(`_attributeValue`, `SAXHandler.swift`) is exactly right: libxml2 re-escapes only a resolved
ampersand, as `&#38;`, so rewriting `&#38;` → `&` is lossless and `&#38;#65;`
correctly recovers the literal `&#65;` the source wrote.

## What is still genuinely out of reach

Short list, and shorter than it was:

- **Whitespace in the epilog** — no callback at all.
- **A BOM-detected (as opposed to declared) input encoding** — not on
  `ctxt->encoding`. Recoverable from `ctxt->input->buf->encoder` if it ever
  matters, which it probably does not.
- **Byte-exact DTD internal-subset formatting** — the declarations round-trip;
  the whitespace and comment placement between them do not, beyond what the
  `comment`/`processingInstruction` handlers report.
- **DTD validity** — see [above](#dtd-validation-is-not-available-in-this-design).

Everything else the old Foundation-era analysis listed as unreachable — the XML
declaration, the DOCTYPE header, attribute order, attribute namespace URIs,
namespace declaration order — is reachable, and most of it is already in hand.

## The error path: two defects, since fixed

Independent of any `Content` change, and the most actionable finding here.
**Both have been fixed**; they are recorded because the failure modes are
non-obvious and because the probe that found them is the same one that produced
everything else above.

They share a root cause. libxml2 does *not* treat "reported a diagnostic" and
"the document failed" as the same thing, and the parser assumed it did — in
opposite directions, which is why the two defects look nothing alike.

| | `wellFormed` | Was |
|---|---|---|
| Level 1 (`XML_ERR_WARNING`) — e.g. code 97, unsupported version | 1 | Latched as a failure, masking the real one |
| Level 2 (`XML_ERR_ERROR`) — e.g. code 201, unbound namespace prefix | **1** | Latched, then silently erased |
| Level 3 (`XML_ERR_FATAL`) — e.g. code 76, tag mismatch | 0 | Handled correctly |

### 1. A warning masked the genuine error

`Context.handleError` latched on the **first** structured error libxml2
reported, regardless of severity. libxml2's `xmlError.level` distinguishes
`XML_ERR_WARNING` (1), `XML_ERR_ERROR` (2), and `XML_ERR_FATAL` (3), and
`LibXMLError` did not capture that field at all. A warning therefore latched
`didLatchFailure`, which then suppressed the real error that followed.

`<?xml version="1.1"?>` is a readily available warning trigger (code 97, level
1, `wellFormed` still 1). Measured through the public API:

| Document | Was thrown | Is thrown now |
|---|---|---|
| `<root>hi</root>` | *parses* | *parses* |
| `<?xml version="1.1"?><root>hi</root>` | *parses* | *parses* |
| `<root>hi</root><extra/>` | `.parseFailure` code 5, "Extra content at the end of the document" | same |
| `<?xml version="1.1"?><root>hi</root><extra/>` | **`.internalFailure`** — diagnostic lost entirely | code 5 |
| `<root>hi</bad>` | `.parseFailure` code 76, "Opening and ending tag mismatch" | same |
| `<?xml version="1.1"?><root>hi</bad>` | **`.parseFailure` code 97, "Unsupported version '1.1'"** — wrong defect reported | code 76 |

Row 2 passed only by luck: `endElement` overwrites `result` with `.success`
when the root closes, erasing the latched warning. Row 4 was that same erasure
turning harmful — `result` held `.success`, `saxParse` returned `false` because
`wellFormed` was 0, and `parse(_:)`'s `sink.context.result.failure ??
Error.internalFailure` fell through to `.internalFailure` with no cause
attached.

`LibXMLError` now captures `error.level` and exposes `isFailure`, true only for
`XML_ERR_ERROR` and above (`LibXMLError.init(_:)` and `LibXMLError.isFailure`);
`Context.handleError(_:)` discards anything else before latching.
Three regression tests cover the interesting rows, under
`MARK: - (advisory diagnostics)` in
`Tests/XestiXMLTests/Parser/XMLParserTests.swift`.

**The severity threshold must stay a severity threshold, not a code list.**
Warning-level diagnostics other than the version one exist — `xml:space="bogus"`
is code 102, level 1 — and they are correctly ignored by the same rule.

### 2. A latched error was erased by the root element closing

Fixing the first defect exposed the second, which is the same misreading of
libxml2 in mirror image: **an error at level 2 leaves `wellFormed` set to 1**,
so the parse runs to completion and `Context.endElement` reaches its
root-element branch and overwrites the latched `.failure` with `.success`.

An unbound namespace prefix is the case that matters — code 201, "Namespace
prefix q on child is not defined". Measured through the public API before the
fix:

```
<root><q:child/></root>       =>  parses; child delivered with uri == nil
<root><child q:id="1"/></root>  =>  parses; attribute delivered as "q:id"
```

Both documents are namespace-ill-formed, libxml2 says so, and the parser threw
the report away and handed the client an element in no namespace at all. That
is the same silent-corruption class the libxml2 migration existed to remove.

`Context.endElement(_:_:)` now assigns `.success` only when no failure is
latched, which is sufficient on its own: `result`
stays `.failure`, and `parse(_:)` throws it whether or not `saxParse` returned
`true`. Two regression tests cover it, in the `(namespaces)` section; both were
confirmed to fail without the guard.

### What was deliberately left alone

**An XML 1.1 document parses, silently, as XML 1.0**, and that is now a
decision rather than an accident. Rejecting it was considered and declined:

- libxml2 already fails on anything outside `1.x` — `version="2.0"` is code
  108 at **level 3**, `wellFormed=0`. Only an unknown *1.x* version is
  downgraded, which is the band where 1.0 processing is most likely correct.
- The observable divergence is narrow: 1.1-only name characters (which surface
  as a well-formedness error regardless, if less clearly) and NEL/U+2028
  line-ending normalization. Measured: `<root>a␅b</root>` draws no diagnostic
  under either declared version, so a 1.1 document using NEL keeps a U+0085
  where 1.1 says LF. That is the entire risk surface.
- Such documents parse today. Rejecting them would be a new failure for
  working input.

It is documented instead, in `XMLParser`'s doc comment
(the *XML 1.1 is not supported* bullet). Should that judgment ever be revisited, the hook is
an exception for **code 97** in `isFailure` — keyed on the code, never on the
level, or `xml:space` would start throwing too — reusing `.parseFailure` rather
than adding a case to the public `Error` enum, which would be source-breaking
for exhaustive switches.

## The maximal `Content`

Dropping `.whitespace` (never fires) and taking the DTD family only as far as it
is actually usable:

```swift
extension XMLNode {
    internal enum Content {
        case cdata(String)                          // Tier 4
        case comment(String)                        // built
        case element(E, [A: String], [XMLNode])     // built
        case entityReference(String, [XMLNode])     // Tier 5
        case processingInstruction(String, String?) // built
        case text(String)                           // built
    }
}
```

Note `.entityReference` carries **children**, not a string — entity replacement
text can be markup (see [Entity boundaries](#entity-boundaries)), so a leaf case
would be wrong in the general case.

Note also what is *absent*: `.element` gains no namespace payload. An earlier
draft of this note proposed `case element(E, [Namespace], [A: String],
[XMLNode])` with a `Namespace` struct of `(prefix: String?, uri: String)`. That
was rejected; see [Tier 3](#recommendation) for the reasoning and for what
replaces it.

**A document-level wrapper is unavoidable if comments, PIs, or the DOCTYPE are
wanted.** Those items occur in the prolog and epilog, outside the root element;
the tree was rooted at the root element (`Context.endElement` sets `result` when
`savedContexts` empties), so there was nowhere to hang them. This is the shape
that was built, and `documentType` is the only name that changed:

```swift
public struct XMLDocument<E: XMLElement, A: XMLAttribute> {
    public let declaration: XMLDeclaration?   // version, encoding, standalone
    public let documentType: XMLDocumentType? // name, publicID, systemID
    public let prolog: [XMLNode<E, A>]        // comments and PIs only
    public let root: XMLNode<E, A>
    public let epilog: [XMLNode<E, A>]
}
```

A wrapper keeps `XMLNode` honest about being a *node*, avoids a `.document` case
legal only at depth 0, and makes the prolog/epilog split explicit in the type —
which the callbacks themselves do not provide.

The wrapper was first built as `XMLTree`, to dodge the fact that Foundation
declares `XMLDocument` on macOS but not on iOS — a name that resolves on one of
this package's two platforms and not the other. That caution was overruled: the
package already ships `XMLParser`, which collides with `Foundation.XMLParser` on
*both* platforms, so the shadowing is a condition callers live with regardless,
and it is the ordinary Swift one that `XestiXML.XMLDocument` disambiguates. The
type is named `XMLDocument`, which is what it is.

Namespace declarations belong on **neither** the node nor `E`. A prefix is
lexical, not informational: `<a:foo xmlns:a="urn:x"/>` and `<b:foo
xmlns:b="urn:x"/>` are the same element, and the type-safe `XMLElement` model is
deliberately keyed on (local name, URI). Putting a prefix in `E` would break
`Equatable` in exactly the way the Namespaces spec forbids — and putting the
declarations on the node reintroduces the same lexical accident one level out,
where it can now *disagree* with the URIs it is supposed to explain. The tree
carries URIs; prefixes are chosen when the tree is written.

The DTD internal subset, if it were ever carried, belongs on `XMLDocumentType`
as a `[Declaration]` — not in `Content`. Its declarations are not nodes and
cannot appear inside the root element.

## Cost of each addition

- **`saxParse`** — one assignment per handler, plus reading three
  `xmlParserCtxt` fields after the final `xmlParseChunk` for the XML
  declaration. Cheapest part of the job.
- **`SAXEventSink`** — every new event needs a no-op method on the non-generic
  base and an override on `XMLParser.EventSink`. Mechanical, but the class is
  the generic barrier, so nothing can shortcut it.
- **`XMLParser.Context`** — must stop discarding, and interleave text, CDATA,
  comments, and PIs in the right order. Note that `flushText()` calls
  `normalizedXMLWhitespace()`, which is lossy;
  CDATA fidelity is incompatible with that normalization, so `.cdata` cannot
  simply reuse the pending-text path.
- **`XMLNode`'s public surface** — `isText`, `value`, `description`, and the
  accessors in `XMLNode.swift` assume the two-case world. In particular
  `_valueOfChildElements` would need to decide whether
  `.cdata` counts toward `value` (it should) and whether `.comment` does (it
  should not).
- **`XMLFormatter.Writer._writeNode`** — an exhaustive `switch`; each case needs a write path, its own escaping rule, and
  a matching `XMLFormatter.Error`: comments must not contain `--` or end in
  `-`, PI data must not contain `?>`, CDATA must not contain `]]>`, and a PI
  target must be an XML name and must not be `xml` in any casing. The
  mixed-content check `children.contains { $0.isText }` in `_writeElement` must
  widen to "contains character data" to
  cover `.cdata`, or pretty-printing will start corrupting element values.
- **The formatter's namespace handling** is the one genuinely large item.
  `_writeElement` does not *record*
  namespaces, it **synthesizes** them — comparing each URI against `currentURI`
  and emitting `xmlns="…"` on change, with a `savedURIs` stack. That is a
  default-namespace-only model, and the reason any attribute beginning with
  `xmlns` throws `reservedAttributeName` in that same attribute loop.
  Handling namespaces properly means replacing synthesis with a **derived
  prefix table** — one pre-pass over the tree collecting the distinct URIs, all
  declarations emitted on the root element — and rewriting the four namespace
  round-trip tests in
  `Tests/XestiXMLTests/Formatter/XMLFormatterTests.swift`. The parser side of
  this is free; the formatter side is most of the work. Note that declaring on
  the root *removes* per-element state rather than adding it: no `currentURI`,
  no `savedURIs`, no scope stack. Playback of recorded declarations would need
  all three, which is one more reason not to record them.

## Recommendation

Ordered by value per unit of work, not by size.

- **Tier 0 — done.** Both defects in
  [The error path: two defects, since fixed](#the-error-path-two-defects-since-fixed)
  have been fixed and covered by tests. Nothing else here depends on them; they
  are listed only so the tiers read as a complete account of what this note
  produced.
- **Tier 1 — done: the XML declaration and DOCTYPE.** See
  [What was built](#what-was-built).
- **Tier 2 — done: `.comment` and `.processingInstruction`.** See
  [What was built](#what-was-built). Built together with Tier 1, as recommended
  — they share the `XMLDocument` wrapper and most of their cost.
- **Tier 3 — done (3a and 3b): namespaces, by deriving prefixes rather than
  storing them.**
  The governing principle: **URIs live in the tree, prefixes live in the
  formatter, and declarations are derived at serialization time.** The tree
  holds only (local name, URI) pairs — which is what `XMLElement` already
  is — so a caller who never thinks about namespaces builds nodes exactly as
  they do today.

  This rejects the `[Namespace]`-on-the-node shape sketched in
  [The maximal `Content`](#the-maximal-content), on grounds of what it does to
  manual AST construction:

  - Every hand-built element carrying a `uri` would need a matching declaration
    somewhere in its ancestry, or the output is unbound-prefix garbage. No type
    can enforce that, so it becomes a class of runtime error that surfaces only
    at serialization.
  - It creates two sources of truth that can disagree — `E.uri` says one
    thing, the in-scope declarations another — and the formatter must then
    either validate (new public error cases) or silently pick one.
  - It makes namespace expertise a *prerequisite* for building a tree by hand,
    rather than an escape hatch for the few who need it.

  Three pieces, in dependency order:

  **3a — `XMLAttribute` gains a `uri`, mirroring `XMLElement`.** This is the
  part that is outright broken today, not merely incomplete. `saxStartElementNs`
  re-joins prefix and local name into `"a:id"` and drops the URI field
  entirely. Since `A` is the *dictionary key*, `a:id` and `b:id` bound to the
  same URI become two distinct keys for one attribute, while `a:id` and a plain
  `id` in no namespace collide in the other direction. The kitchen-sink document
  in [Method](#method) exercises both.

  ```swift
  public protocol XMLAttribute: Equatable, Hashable, Sendable {
      init(_ name: String, _ uri: String?)
      init?(name: String, uri: String?)
      var name: String { get }
      var uri: String? { get }
  }
  ```

  The `RawRepresentable` and `StringRepresentable` default extensions supply
  `uri == nil` and reject a non-nil URI, exactly as they already do for
  `XMLElement`.

  **This much was verified by probe, not assumed** — 3a was applied to the
  package, built, and reverted (the patch is 224 lines across five files). The
  result splits in a way the first draft of this note got wrong:

  - **Conformance declarations do survive.** `SRTestAttribute`
    (`StringRepresentable`) and `TestAttribute` (a `String` raw-value enum)
    produced no conformance diagnostics at all. The defaults carry them, as
    predicted.
  - **`Sources/` compiled clean** with a single one-line change:
    `A(name: name)` → `A(name: name, uri: nil)` in `Context.startElement`.
  - **Hand-written conformances break**, as predicted. `Test3Attribute` failed
    with *type does not conform to protocol `XMLAttribute`*.
  - **But every *call site* of the initializers breaks too, regardless of
    conformance kind** — and that is the part the draft missed.
    `TestAttribute` keeps conforming, yet `TestAttribute(name: "id")` and
    `TestAttribute("id")` both stop compiling, because the protocol's
    initializer signatures are what changed. The diagnostic for the unlabeled
    form is actively misleading:
    *missing argument label `rawValue:` in call*, because once the protocol's
    `init(_:)` is gone the only remaining single-`String` initializer is the
    enum's synthesized `init?(rawValue:)`.

  So the blast radius is wider than "hand-written conformances": it is every
  construction site of an attribute value in client code. Within this package
  that was 8 call sites across two test files, all mechanical. It is firmly a
  major-version item. After fixing the conformance and the call sites, all 289
  tests passed and `make lint` reported 0 violations.

  **3b — the formatter computes a prefix table and declares on the root.**
  Replace the `currentURI`/`savedURIs` synthesis in `_writeElement` with one
  pre-pass collecting the distinct URIs in the tree:

  ```swift
  public struct Namespace: Hashable, Sendable {
      public let prefix: String?  // nil = default namespace
      public let uri: String
  }
  // XMLFormatter.Options.namespaces: [Namespace] = []
  ```

  Resolution is deterministic and total, so it needs no new `XMLFormatter.Error`
  case — which matters, given that both error enums now document that added
  cases break exhaustive switches:

  1. A URI listed in `options.namespaces` takes the prefix given, and the
     declarations are emitted in list order.
  2. An unlisted URI becomes the default namespace only if *every* element in
     the tree carries it; otherwise it takes a generated `ns1`, `ns2`, … in
     document order.
  3. `http://www.w3.org/XML/1998/namespace` is always `xml` and is never
     declared.

  Rule 2 preserves today's output for the common single-namespace document, and
  it sidesteps `xmlns=""` undeclaration entirely: the default namespace is used
  only when no element needs to escape it.

  The trap any implementation must respect: **an unprefixed attribute is in no
  namespace, never the default one.** An attribute with a non-nil URI therefore
  always needs a real prefix, even when that URI is the element default. This is
  the rule hand-rolled namespace serializers most often get wrong.

  **3c — optional: `XMLDocument.namespaces` for prefix-preserving round trips.**
  If byte-level prefix fidelity is ever wanted, the parser can capture the root
  element's declarations into a property on the wrapper, which the formatter
  then uses as its default table. One property on `XMLDocument`, alongside
  `declaration` and `documentType` — not a payload on every element. Its limit
  should be stated plainly: a document that rebinds one prefix to different URIs
  at different depths flattens to a document-level table and re-serializes to
  *semantically* identical XML — every name resolves to the same URI — but
  not textually identical. Ship 3a and 3b first; add this only on evidence
  that someone diffs output.
- **Tier 4 — skipped: `.cdata` distinct from `.text`.** Only byte fidelity
  motivates it, and it requires revisiting `normalizedXMLWhitespace()`, which is
  a behavior change for every existing caller, not just for CDATA. CDATA is
  already parsed correctly; it simply arrives as text, which is what nearly
  every consumer wants.
- **Tier 5 — skipped: entity boundaries.** `reference` is additive and
  well-behaved, but `.entityReference` must carry children to be correct, the
  events arrive after their content, and they nest without depth markers.
  Real complexity for a rare need.
- **Tier 6 — skipped: the DTD declaration family.** This is a reversal of what
  the Foundation-era analysis concluded, and for a good reason: the content
  models and attribute types that were previously empty strings now arrive
  complete, so the declarations *could* be modeled and re-serialized faithfully.
  But nothing in this package consumes a DTD, no external subset is ever loaded,
  and validation is unavailable in this design. Preserving the internal subset
  would carry inert data through the tree. Skipped on grounds of demand, not
  capability — and note that if demand appears, the capability is there.
- **DTD-defaulted attributes — decided: keep reporting them.** `nb_defaulted`
  identifies them exactly, so suppressing them would be a one-line change
  (`0..<Int(attrCount - defaultedCount)`) that would eliminate the surprising
  `unrecognizedAttribute` for an attribute appearing nowhere in the source. It
  was rejected anyway. A defaulted attribute is part of the document by XML's
  own rules — a non-validating processor that reads an internal subset is
  *required* to supply it — so suppressing it trades a loud, fixable error for
  a silent wrong answer: `attributes[.someAttr]` yields `nil` for a value the
  document genuinely carries, with nothing to explain why. That is also the
  opposite of the polarity chosen everywhere else in this round, where the
  parser stopped discarding things by default.

  The pain is narrow: it bites only when a document has an internal subset with
  an `<!ATTLIST>` *and* the caller's `XMLAttribute` type omits the defaulted
  name, and the fix is one enum case they would need anyway the moment someone
  writes that attribute explicitly. The behavior is now documented as intended
  in `XMLParser.swift` rather than listed as a limitation.

  Worth revisiting only if opt-in external subset loading is ever added: whole
  vocabularies of defaulted attributes would appear at once, and suppression
  could then be scoped to *externally* declared defaults — a far better-targeted
  rule than a global one, and one that would live behind that option.

Tiers 4, 5, and 6 are **closed, most likely permanently.** None of them is
blocked by libxml2; each was measured and found to be within reach. They are
declined because the cost lands on every caller — a normalization change, a
recursive `Content` case, or inert DTD data threaded through the tree — while
the benefit lands on almost none. Reopening any of them should require a
concrete consumer, not a tidiness argument. The measurements above are what
makes that reversible: the analysis need not be redone, only the decision.

Tier 3 steps **3a and 3b have since been implemented**; see
[What was built](#what-was-built). Step 3c — capturing the source's own
prefixes on `XMLDocument` for byte-identical round trips — was not built, and
remains the only part of this note that is open.

## What was built

Tiers 1 and 2 have been implemented together, as the recommendation suggested.
The design decisions worth recording:

**Retention is the default; discarding is opt-in.** The premise of this note is
that the parser should stop throwing information away, so the default set of
options keeps everything it can represent, and `XMLParser.Options` is phrased in
terms of what it *strips*:

```swift
XMLParser<E, A>()                       // comments and PIs become nodes
XMLParser<E, A>(options: .init(stripsComments: true,
                               stripsProcessingInstructions: true))
```

There is deliberately no `.stripsAll` shorthand. It would name a promise rather
than a list, so adding a third strip option later would silently widen what it
discards at every existing call site.

This does change what the root-element entry point returns for a document
containing comments or processing instructions inside element content: they now
appear in `children`, so counts and iteration shift. `value` and
`allChildElements()` are unaffected, since neither kind is character data or an
element. The break is deliberate and belongs in the release notes.

`XMLFormatter.Options` carries the same two properties, with the same names and
the same defaults, so a tree may be stripped as it is parsed, as it is
formatted, or both. Stripping on the formatting side happens before anything is
written — an element left with no children becomes an empty element, a stripped
child leaves no indented blank line behind, and a node that is never written is
never validated.

The XML declaration and the DOCTYPE are *not* gated — they sit outside the root
element, so nothing existing can see them either way.

**`XMLDocument` is the document wrapper**, holding `declaration`,
`documentType`, `prolog`, `root`, and `epilog`. `XMLParser.parse(_:)` returns it
and `XMLFormatter.format(_:)` accepts it; these are the only entry points.

(This was written when the wrapper was named `XMLTree` and its methods were
additions — `parseTree(_:)` and a `format(_:)` overload — sitting alongside
root-element versions. Both root-element versions were subsequently removed and
the wrapper versions took the plain names. The reasoning: `parse(data).root` and
`XMLDocument(root: node)` are each a one-liner, so the pair bought nothing but a
second way to spell the same call — and on the parse side, the short name
belonged to the operation that silently discards the DOCTYPE and the prolog.
Written out, the discard is visible at the call site. The type was renamed
`XMLDocument` later still; earlier prose in this note still calls the
root-element method `parse(_:)`.)

**Three positions, one pair of callbacks.** As predicted, `comment` and
`processingInstruction` carry no positional marker, so `Context` tracks its own:
inside an element the node joins `pendingChildren`, before the root it joins the
prolog, after the root the epilog.

**Comments inside the internal DTD subset are always dropped**, since there is
nowhere to represent them. Separating them from prolog comments needs an "end of
internal subset" signal, which libxml2 does not offer directly — but it calls
`externalSubset` at exactly that point. That is verified for every shape of
DOCTYPE (bare, empty subset, populated subset, external identifier), and
`startElement` clears the flag as a second line of defence.

**The XML declaration needed no handler**, as expected: `ctxt->version`,
`ctxt->encoding`, and `ctxt->standalone` are read in `saxParse` once the parse
completes. `standalone == -1` is what distinguishes "no declaration" from "no
`standalone` pseudo-attribute", exactly as measured.

The formatter gained the inverse of all of it, plus the validation each new node
kind needs — no `--` or trailing `-` in a comment, no `?>` in PI data, a PI
target that is an XML name and not `xml` in any casing, a public identifier
restricted to `PubidChar`, a system identifier not containing both quote
characters, and a version matching `VersionNum`. Each has its own
`XMLFormatter.Error` case.

Not attempted, and worth knowing: **whitespace between top-level items is not
represented**, so a compactly formatted document runs its prolog, root, and
epilog together. Line breaks there are a function of `indentation`, consistent
with how the formatter already treats element content.

### Tier 3, as built

Steps 3a and 3b landed together; 3c was not built. What is worth recording
beyond the recommendation itself:

**The prefix is discarded at the callback.** `saxStartElementNs` now reads field
2 of each attribute 5-tuple (the URI) and ignores field 1 (the prefix), where it
previously joined field 1 and field 0 into `"a:id"`. The dictionary it built is
now a `[SAXAttribute]` array, because a dictionary keyed on the name alone
cannot hold both `a:id` and a plain `id` — it silently dropped one. That is
the concrete bug 3a fixes, and `parse_namespacedAttributes` is the test that
used to pin the wrong behavior.

**`NamespaceTable` is where every prefix decision lives.** It is built once per
document, before a byte is written, and the writer asks it for a name rather
than reasoning about scope. `currentURI` and `savedURIs` are gone from
`Writer` — declaring at the root means no declaration is ever overridden, so
there is no scope to push or pop. The writer got smaller, which was predicted
and is worth noting because it is the opposite of what carrying declarations on
the node would have cost.

**Names are validated as NCNames now, not names.** `isXMLName` admits a colon;
element and attribute local names may no longer contain one, since the prefix is
the formatter's to add. The `xmlns` reservation is checked *before* that, so a
caller who writes `xmlns:foo` as an ordinary attribute still gets
`reservedAttributeName` naming their actual mistake rather than a complaint
about a colon.

**One new error case, contrary to the recommendation.** The design above claimed
resolution needed no new `XMLFormatter.Error` case, and that is true of
resolution — every URI in a tree gets a prefix, always. It is not true of the
*bindings the caller supplies*: a prefix containing a colon, a prefix of `xml`
or `xmlns`, an empty URI, the xmlns URI, or the same prefix or URI bound twice
all have to be rejected rather than silently repaired, so
`invalidNamespace(String?, String)` was added. Since 3a already forces a major
version, the cost of the added case is nil — but the earlier claim was wrong
and is corrected here rather than quietly dropped.

**Bindings are declared whether or not they are used.** A URI listed in
`Options.namespaces` is emitted on the root even if no name in the tree
resolves to it. Predictability was preferred to tidiness: the declarations a
given set of options produces should not depend on a tree walk.

**What round trips and what does not.** A single-namespace document round-trips
byte for byte, because the sole URI becomes the default namespace — the common
case is unchanged from before. A multi-namespace document does not: it comes
back with generated prefixes. `roundTrip_namespacedDocument` pins the new text
and `roundTrip_namespacedDocumentIsStable` pins the property that actually
matters, that formatting is idempotent from there on.

### `xml:space`, as built

Not part of the original tier list — it surfaced when IvorMusicXML, the first
consumer, turned out to depend on it. MusicXML uses `xml:space="preserve"` on
lyric and credit text, where a trailing space is how a syllable joins the one
after it, so normalizing it away changes what gets rendered. Measured before the
fix: `<text xml:space="preserve">the </text>` and `<text>the </text>` both
yielded `the`. The attribute was recorded faithfully and ignored completely.

**The mode is inherited, so it is scope state.** `Context` tracks a
`preservesSpace` flag saved and restored alongside the enclosing element. That
forced `SavedContext` from a tuple to a struct: `.swiftlint.yml` sets
`large_tuple` to warning at 3 and **error at 4**, and the flag would have been
the fourth member.

**Flush ordering is load-bearing.** `flushText()` has three call sites, and each
must run under the mode of the element the text belongs to — the parent's in
`startElement`, the closing element's in `endElement`, the current one's in
`_appendNode`. All three already flushed before changing state, so no call site
moved, but the requirement is now stated in the doc comment rather than left to
be rediscovered.

**The mode is read from the raw `SAXAttribute` list**, not from the converted
attributes, so it is settled before a caller's `XMLAttribute` type can abort the
parse by rejecting some unrelated name.

**A whitespace-only run becomes a text node** under preservation instead of
vanishing. That is the change that shifts `children` counts for anyone parsing
such a document, and it belongs in release notes next to the comment-retention
break.

**The formatter suppresses indentation inside a preserved subtree.** The
mixed-content check catches most of it for free once whitespace text nodes
exist, but `<pre xml:space="preserve"><b/></pre>` has no text at all, so
`_writeElement` checks the attribute directly. An inherited suppression is
deliberately never lifted, not even by a descendant asking for
`xml:space="default"`: erring towards less indentation can only make the output
plainer, while erring the other way would change what a document says.

**Escaping needed no change**, which was worth checking rather than assuming.
`_escapedXML(inAttributeValue: false)` already passes newlines and tabs through
literally and escapes carriage return as `&#xd;` — necessary, since a literal CR
would be normalized to LF on any re-parse. Preserved whitespace survives a round
trip exactly as written.

**Not gated behind an option.** Honoring `xml:space` is what XML 1.0 requires,
so it is a defect fixed rather than a feature offered. An invalid value is
ignored rather than rejected, since libxml2 reports it only as a warning and
`isFailure` discards those by design.

## Remaining open questions

- ~~Whether `XMLAttribute` should gain a `uri` property.~~ Done, as Tier 3 step
  **3a**. The old qualified-name behavior (`a:id`) made the prefix — a lexical
  accident of the source — part of client-visible identity, and specifically
  part of the *dictionary key*. What remains open is only the release it lands
  in: it breaks every attribute construction site in client code, not merely
  hand-written conformances, so it should ship with whatever else is breaking
  rather than alone.
- Whether `normalizedXMLWhitespace()` should stay unconditional. **Partly
  answered:** it is no longer unconditional, because `xml:space` is now
  honored — see [`xml:space`, as built](#xmlspace-as-built). What remains open
  is whether a caller-wide `XMLParser.Options` property should exist *as well*,
  for documents that need preservation without saying so. The document asking
  is a far better signal than a global flag, so this should wait for a case the
  attribute cannot express.
- Whether libxml2 version skew across the iOS 16 → 26 support range affects any
  of this. Both current SDKs ship 2.9.13; every handler and struct field used
  above has been stable since 2.6.
