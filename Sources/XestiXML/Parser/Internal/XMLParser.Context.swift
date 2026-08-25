// © 2022–2026 John Gary Pusey (see LICENSE.md)

private import XestiTools

extension XMLParser {

    // MARK: Internal Nested Types

    internal struct Context {

        // MARK: Internal Initializers

        internal init(_ options: Options) {
            self.epilog = []
            self.options = options
            self.pendingAttributes = [:]
            self.pendingChildren = []
            self.pendingText = ""
            self.prolog = []
            self.result = .failure(.internalFailure)
            self.savedContexts = []
            self.shouldAbort = false
        }

        // MARK: Internal Instance Properties

        internal private(set) var declaration: XMLDeclaration?
        internal private(set) var documentType: XMLDocumentType?
        internal private(set) var epilog: [XMLNode<E, A>]
        internal private(set) var prolog: [XMLNode<E, A>]
        internal private(set) var result: Result<XMLNode<E, A>, Error>
        internal private(set) var shouldAbort: Bool

        // MARK: Private Nested Types

        //  The enclosing element's state, set aside while a child is being
        //  built. `preservesSpace` rides along because `xml:space` is inherited
        //  by descendants and must be restored, not merely cleared, when the
        //  child closes.
        private struct SavedContext {
            fileprivate let attributes: [A: String]
            fileprivate let children: [XMLNode<E, A>]
            fileprivate let element: E
            fileprivate let preservesSpace: Bool
        }

        // MARK: Private Instance Properties

        private let options: Options

        private var didEndRoot: Bool = false
        private var didLatchFailure: Bool = false
        private var isInInternalSubset: Bool = false
        private var pendingAttributes: [A: String]
        private var pendingChildren: [XMLNode<E, A>]
        private var pendingElement: E?
        private var pendingText: String
        private var preservesSpace: Bool = false
        private var savedContexts: [SavedContext]
        private var unrecognizedAttribute: String?
        private var unrecognizedElement: (String, String?)?
    }
}

// MARK: -

extension XMLParser.Context {

    // MARK: Internal Instance Methods

    internal mutating func appendComment(_ text: String) {
        guard !options.stripsComments
        else { return }

        _appendNode(XMLNode(comment: text))
    }

    internal mutating func appendProcessingInstruction(_ target: String,
                                                       _ data: String?) {
        guard !options.stripsProcessingInstructions
        else { return }

        _appendNode(XMLNode(processingInstruction: target,
                            data: data))
    }

    internal mutating func appendText(_ text: String) {
        pendingText += text
    }

    internal mutating func endElement(_ name: String,
                                      _ uri: String?) {
        let normalizedURI = uri?.nilIfEmpty

        guard let elem = pendingElement,
              elem.name == name,
              elem.uri == normalizedURI
        else { return }

        flushText()

        let element: XMLNode<E, A> = XMLNode(element: elem,
                                             attributes: pendingAttributes,
                                             children: pendingChildren)

        if let context = savedContexts.popLast() {
            pendingAttributes = context.attributes
            pendingChildren = context.children
            pendingElement = context.element
            preservesSpace = context.preservesSpace

            pendingChildren.append(element)
        } else {
            pendingAttributes = [:]
            pendingChildren = []
            pendingElement = nil

            //  A latched failure must survive the root element closing over
            //  it. libxml2 reports some defects — an unbound namespace prefix,
            //  for one — without clearing `wellFormed`, so the parse runs to
            //  completion and this is the only thing standing between such a
            //  document and a silent success.
            if !didLatchFailure {
                result = .success(element)
            }

            didEndRoot = true
        }
    }

    internal mutating func endInternalSubset() {
        isInInternalSubset = false
    }

    //  Turns whatever text has accumulated into a node, if there is any.
    //
    //  Whitespace is normalized unless the enclosing element is under
    //  `xml:space="preserve"`, in which case the run is taken verbatim — and a
    //  run of nothing but whitespace becomes a text node of its own rather than
    //  vanishing, which is the whole point of asking for preservation.
    //
    //  Every caller must invoke this before changing `preservesSpace`, since
    //  the text accumulated so far belongs to the element that was open when it
    //  arrived.
    internal mutating func flushText() {
        let text = preservesSpace ? pendingText : pendingText.normalizedXMLWhitespace()

        pendingText = ""

        guard !text.isEmpty
        else { return }

        pendingChildren.append(XMLNode(text: text))
    }

    //  Records the failure that caused `parse(_:)` to be aborted by us.
    //
    //  libxml2 does not report an error of its own when `xmlStopParser` is
    //  called, so the position must be captured by the caller at the moment of
    //  the abort. An abort always takes precedence over any error libxml2 may
    //  already have reported.
    internal mutating func handleAbort(_ line: Int,
                                       _ column: Int) {
        if let attr = unrecognizedAttribute {
            result = .failure(.unrecognizedAttribute(attr, line, column))
        } else if let (name, uri) = unrecognizedElement {
            result = .failure(.unrecognizedElement(name, uri, line, column))
        } else {
            result = .failure(.parseFailure(nil, line, column))
        }

        didLatchFailure = true
    }

    //  Records a structured error reported by libxml2.
    //
    //  libxml2 can report several errors for a single document; only the first
    //  is retained, so that a trailing cascade never masks the actual defect.
    //
    //  Advisory diagnostics are discarded outright. Were one to be latched, it
    //  would both misreport the defect and — because it is not itself fatal —
    //  suppress the genuine error that follows it.
    internal mutating func handleError(_ error: LibXMLError) {
        guard error.isFailure,
              !didLatchFailure
        else { return }

        result = .failure(.parseFailure(error, error.line, error.column))

        didLatchFailure = true
    }

    internal mutating func setDeclaration(_ version: String?,
                                          _ encoding: String?,
                                          _ standalone: Int32) {
        //  A version is reported even when the document carries no XML
        //  declaration at all — libxml2 defaults it to 1.0 — so the standalone
        //  encoding is the only reliable indicator that there was one.
        guard standalone != noXMLDeclaration
        else { return }

        declaration = XMLDeclaration(version: version ?? "1.0",
                                     encoding: encoding,
                                     isStandalone: standalone == noStandaloneValue
                                         ? nil
                                         : standalone == 1)
    }

    internal mutating func setDocumentType(_ name: String,
                                           _ publicID: String?,
                                           _ systemID: String?) {
        documentType = XMLDocumentType(name: name,
                                       publicID: publicID?.nilIfEmpty,
                                       systemID: systemID?.nilIfEmpty)

        isInInternalSubset = true
    }

    internal mutating func startElement(_ name: String,
                                        _ uri: String?,
                                        _ attributes: [SAXAttribute]) {
        //  Belt and braces: the internal subset cannot still be open once an
        //  element has begun, whatever libxml2 did or did not report.
        isInInternalSubset = false

        //  Any text gathered so far belongs to the enclosing element, so it
        //  must be flushed under *that* element's whitespace mode, before this
        //  one's `xml:space` is applied below.
        flushText()

        let normalizedURI = uri?.nilIfEmpty

        guard let elem = E(name: name,
                           uri: normalizedURI)
        else {
            unrecognizedElement = (name, normalizedURI)
            shouldAbort = true

            return
        }

        if let pendElem = pendingElement {
            savedContexts.append(SavedContext(attributes: pendingAttributes,
                                              children: pendingChildren,
                                              element: pendElem,
                                              preservesSpace: preservesSpace))
        }

        pendingAttributes = [:]
        pendingChildren = []
        pendingElement = elem

        //  Read from the raw attributes rather than the converted ones, so that
        //  the mode is settled before any of the conversions below can abort.
        if let mode = Self._spaceMode(attributes) {
            preservesSpace = mode
        }

        for attribute in attributes {
            let attributeURI = attribute.uri?.nilIfEmpty

            guard let attr = A(name: attribute.name,
                               uri: attributeURI)
            else {
                unrecognizedAttribute = attribute.name
                shouldAbort = true

                return
            }

            pendingAttributes[attr] = attribute.value
        }
    }

    // MARK: Private Type Methods

    //  The whitespace mode an element's `xml:space` attribute asks for, or nil
    //  to inherit whatever the enclosing element was using.
    //
    //  XML 1.0 defines exactly two values. Anything else is invalid, and a
    //  non-validating parser is not obliged to reject it — libxml2 reports it
    //  only as a warning, which `isFailure` discards — so an unrecognized value
    //  is treated as if the attribute were absent.
    private static func _spaceMode(_ attributes: [SAXAttribute]) -> Bool? {
        guard let attribute = attributes.first(where: { $0.name == "space"
                                                        && $0.uri == xmlNamespaceURI
        })
        else { return nil }

        switch attribute.value {
        case "default":
            return false

        case "preserve":
            return true

        default:
            return nil
        }
    }

    // MARK: Private Instance Methods

    //  Places a comment or processing instruction node where it belongs: among
    //  the children of the enclosing element or, outside the root element, in
    //  the prolog or the epilog. Nothing on the event says which of the three
    //  applies, so the position has to be tracked here.
    //
    //  Comments and processing instructions within the internal subset of a
    //  document type declaration arrive through these very same callbacks, and
    //  there is nowhere to represent them, so they are dropped.
    private mutating func _appendNode(_ node: XMLNode<E, A>) {
        guard !isInInternalSubset
        else { return }

        if pendingElement != nil {
            flushText()

            pendingChildren.append(node)
        } else if didEndRoot {
            epilog.append(node)
        } else {
            prolog.append(node)
        }
    }
}

// MARK: - Private Constants

//  libxml2's four-way encoding of `xmlParserCtxt.standalone`. The two positive
//  values are `standalone="yes"` and `standalone="no"`.
private let noStandaloneValue: Int32 = -2
private let noXMLDeclaration: Int32 = -1

private let xmlNamespaceURI = "http://www.w3.org/XML/1998/namespace"
