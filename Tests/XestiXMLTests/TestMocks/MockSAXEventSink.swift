// © 2026 John Gary Pusey (see LICENSE.md)

@testable import XestiXML

//  Records every event reported to a `SAXEventSink`, so that the free
//  functions in `SAXHandler.swift` and the driving function in `SAXParser.swift`
//  can be tested without a generic `XMLParser.EventSink` in the way.
internal final class MockSAXEventSink: SAXEventSink {

    // MARK: Internal Instance Properties

    internal private(set) var abortedAt: (line: Int, column: Int)?
    internal private(set) var comments: [String] = []
    internal private(set) var declarations: [(version: String?, encoding: String?, standalone: Int32)] = []
    internal private(set) var didEndInternalSubset = false
    internal private(set) var documentTypes: [(name: String, publicID: String?, systemID: String?)] = []
    internal private(set) var endedElements: [(name: String, uri: String?)] = []
    internal private(set) var errors: [LibXMLError] = []
    internal private(set) var processingInstructions: [(target: String, data: String?)] = []
    internal private(set) var startedElements: [(name: String, uri: String?, attributes: [SAXAttribute])] = []
    internal private(set) var texts: [String] = []

    internal var stubbedShouldAbort = false

    // MARK: Overridden Internal Instance Properties

    override internal var shouldAbort: Bool {
        stubbedShouldAbort
    }

    // MARK: Overridden Internal Instance Methods

    override internal func appendComment(_ text: String) {
        comments.append(text)
    }

    override internal func appendProcessingInstruction(_ target: String,
                                                       _ data: String?) {
        processingInstructions.append((target, data))
    }

    override internal func appendText(_ text: String) {
        texts.append(text)
    }

    override internal func endElement(_ name: String,
                                      _ uri: String?) {
        endedElements.append((name, uri))
    }

    override internal func endInternalSubset() {
        didEndInternalSubset = true
    }

    override internal func handleAbort(_ line: Int,
                                       _ column: Int) {
        abortedAt = (line, column)
    }

    override internal func handleError(_ error: LibXMLError) {
        errors.append(error)
    }

    override internal func setDeclaration(_ version: String?,
                                          _ encoding: String?,
                                          _ standalone: Int32) {
        declarations.append((version, encoding, standalone))
    }

    override internal func setDocumentType(_ name: String,
                                           _ publicID: String?,
                                           _ systemID: String?) {
        documentTypes.append((name, publicID, systemID))
    }

    override internal func startElement(_ name: String,
                                        _ uri: String?,
                                        _ attributes: [SAXAttribute]) {
        startedElements.append((name, uri, attributes))
    }
}
