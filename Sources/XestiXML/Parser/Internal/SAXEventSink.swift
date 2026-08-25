// © 2026 John Gary Pusey (see LICENSE.md)

// The non-generic boundary between libxml2’s `@convention(c)` callbacks and
// the generic tree-building machinery.
//
// A C function pointer cannot be formed from a closure that captures generic
// parameters, so the callbacks in `SAXHandler.swift` cannot mention `E` or
// `A`. They talk to this class instead; `XMLParser.EventSink` subclasses it
// and supplies the actual behavior.
internal class SAXEventSink {

    // MARK: Internal Initializers

    internal init() {
    }

    // MARK: Internal Instance Properties

    internal var shouldAbort: Bool {
        false
    }

    // MARK: Internal Instance Methods

    internal func appendComment(_ text: String) {
        // no-op; see `XMLParser.EventSink`
    }

    internal func appendProcessingInstruction(_ target: String,
                                              _ data: String?) {
        // no-op; see `XMLParser.EventSink`
    }

    internal func appendText(_ text: String) {
        // no-op; see `XMLParser.EventSink`
    }

    internal func endElement(_ name: String,
                             _ uri: String?) {
        // no-op; see `XMLParser.EventSink`
    }

    internal func endInternalSubset() {
        // no-op; see `XMLParser.EventSink`
    }

    internal func handleAbort(_ line: Int,
                              _ column: Int) {
        // no-op; see `XMLParser.EventSink`
    }

    internal func handleError(_ error: LibXMLError) {
        // no-op; see `XMLParser.EventSink`
    }

    //  Reports the XML declaration, read from the parser context once the parse
    //  has run to completion.
    //
    //  `standalone` is libxml2’s four-way encoding: `1` for `standalone="yes"`,
    //  `0` for `standalone="no"`, `-1` for no XML declaration at all, and `-2`
    //  for a declaration carrying no `standalone` pseudo-attribute.
    internal func setDeclaration(_ version: String?,
                                 _ encoding: String?,
                                 _ standalone: Int32) {
        // no-op; see `XMLParser.EventSink`
    }

    internal func setDocumentType(_ name: String,
                                  _ publicID: String?,
                                  _ systemID: String?) {
        // no-op; see `XMLParser.EventSink`
    }

    internal func startElement(_ name: String,
                               _ uri: String?,
                               _ attributes: [SAXAttribute]) {
        // no-op; see `XMLParser.EventSink`
    }
}
