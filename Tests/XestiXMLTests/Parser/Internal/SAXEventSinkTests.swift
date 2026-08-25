// © 2026 John Gary Pusey (see LICENSE.md)

import libxml2
import Testing
@testable import XestiXML

struct SAXEventSinkTests {
}

// MARK: -

extension SAXEventSinkTests {
    @Test
    func appendComment_isNoOp() {
        SAXEventSink().appendComment("note")
    }

    @Test
    func appendProcessingInstruction_isNoOp() {
        SAXEventSink().appendProcessingInstruction("pi", "data")
    }

    @Test
    func appendText_isNoOp() {
        SAXEventSink().appendText("hello")
    }

    @Test
    func endElement_isNoOp() {
        SAXEventSink().endElement("root", nil)
    }

    @Test
    func endInternalSubset_isNoOp() {
        SAXEventSink().endInternalSubset()
    }

    @Test
    func handleAbort_isNoOp() {
        SAXEventSink().handleAbort(1, 1)
    }

    @Test
    func handleError_isNoOp() {
        SAXEventSink().handleError(LibXMLError(xmlError()))
    }

    @Test
    func setDeclaration_isNoOp() {
        SAXEventSink().setDeclaration("1.0", "UTF-8", 0)
    }

    @Test
    func setDocumentType_isNoOp() {
        SAXEventSink().setDocumentType("root", nil, nil)
    }

    @Test
    func shouldAbort_defaultsToFalse() {
        #expect(!SAXEventSink().shouldAbort)
    }

    @Test
    func startElement_isNoOp() {
        SAXEventSink().startElement("root", nil, [])
    }
}
