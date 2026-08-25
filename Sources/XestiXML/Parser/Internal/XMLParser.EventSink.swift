// © 2026 John Gary Pusey (see LICENSE.md)

extension XMLParser {

    // MARK: Internal Nested Types

    internal final class EventSink: SAXEventSink {

        // MARK: Internal Initializers

        internal init(_ options: Options) {
            self.context = Context(options)

            super.init()
        }

        // MARK: Internal Instance Properties

        internal private(set) var context: Context

        // MARK: Overridden Internal Instance Properties

        override internal var shouldAbort: Bool {
            context.shouldAbort
        }

        // MARK: Overridden Internal Instance Methods

        override internal func appendComment(_ text: String) {
            context.appendComment(text)
        }

        override internal func appendProcessingInstruction(_ target: String,
                                                           _ data: String?) {
            context.appendProcessingInstruction(target,
                                                data)
        }

        override internal func appendText(_ text: String) {
            context.appendText(text)
        }

        override internal func endElement(_ name: String,
                                          _ uri: String?) {
            context.endElement(name,
                               uri)
        }

        override internal func endInternalSubset() {
            context.endInternalSubset()
        }

        override internal func handleAbort(_ line: Int,
                                           _ column: Int) {
            context.handleAbort(line,
                                column)
        }

        override internal func handleError(_ error: LibXMLError) {
            context.handleError(error)
        }

        override internal func setDeclaration(_ version: String?,
                                              _ encoding: String?,
                                              _ standalone: Int32) {
            context.setDeclaration(version,
                                   encoding,
                                   standalone)
        }

        override internal func setDocumentType(_ name: String,
                                               _ publicID: String?,
                                               _ systemID: String?) {
            context.setDocumentType(name,
                                    publicID,
                                    systemID)
        }

        override internal func startElement(_ name: String,
                                            _ uri: String?,
                                            _ attributes: [SAXAttribute]) {
            context.startElement(name,
                                 uri,
                                 attributes)
        }
    }
}
