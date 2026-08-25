// © 2026 John Gary Pusey (see LICENSE.md)

import libxml2
import Testing
import XestiTools
@testable import XestiXML

struct XMLParserEventSinkTests {
}

// MARK: -

extension XMLParserEventSinkTests {
    @Test
    func appendComment_addsCommentToContext() throws {
        let sink = Test2Parser.EventSink(Test2Parser.Options())

        sink.startElement("root", nil, [])
        sink.appendComment("note")
        sink.endElement("root", nil)

        let node = try #require(sink.context.result.success)

        #expect(node.children?.first?.comment == "note")
    }

    @Test
    func appendProcessingInstruction_addsNodeToContext() throws {
        let sink = Test2Parser.EventSink(Test2Parser.Options())

        sink.startElement("root", nil, [])
        sink.appendProcessingInstruction("pi", "data")
        sink.endElement("root", nil)

        let node = try #require(sink.context.result.success)

        #expect(node.children?.first?.target == "pi")
    }

    @Test
    func appendText_addsTextToContext() throws {
        let sink = Test2Parser.EventSink(Test2Parser.Options())

        sink.startElement("root", nil, [])
        sink.appendText("hello")
        sink.endElement("root", nil)

        let node = try #require(sink.context.result.success)

        #expect(node.value == "hello")
    }

    @Test
    func endElement_closesElementInContext() throws {
        let sink = Test2Parser.EventSink(Test2Parser.Options())

        sink.startElement("root", nil, [])
        sink.endElement("root", nil)

        let node = try #require(sink.context.result.success)

        #expect(node.element == .root)
    }

    @Test
    func endInternalSubset_isForwardedToContext() {
        let sink = Test2Parser.EventSink(Test2Parser.Options())

        sink.setDocumentType("root", nil, nil)
        sink.endInternalSubset()
        sink.appendComment("note")

        #expect(sink.context.prolog.first?.comment == "note")
    }

    @Test
    func handleAbort_recordsFailureInContext() {
        let sink = Test2Parser.EventSink(Test2Parser.Options())

        sink.handleAbort(3, 5)

        guard case let .parseFailure(_, line, column) = sink.context.result.failure
        else {
            Issue.record("Expected parseFailure error")

            return
        }

        #expect(line == 3)
        #expect(column == 5)
    }

    @Test
    func handleError_recordsFailureInContext() {
        let sink = Test2Parser.EventSink(Test2Parser.Options())
        var xmlErr = xmlError()

        xmlErr.level = XML_ERR_ERROR
        xmlErr.line = 7

        sink.handleError(LibXMLError(xmlErr))

        guard case let .parseFailure(_, line, _) = sink.context.result.failure
        else {
            Issue.record("Expected parseFailure error")

            return
        }

        #expect(line == 7)
    }

    @Test
    func init_contextReflectsOptions() {
        let sink = Test2Parser.EventSink(Test2Parser.Options(stripsComments: true))

        sink.appendComment("note")

        #expect(sink.context.prolog.isEmpty)
    }

    @Test
    func setDeclaration_recordsDeclarationInContext() {
        let sink = Test2Parser.EventSink(Test2Parser.Options())

        sink.setDeclaration("1.0", "UTF-8", 0)

        #expect(sink.context.declaration?.encoding == "UTF-8")
    }

    @Test
    func setDocumentType_recordsDocumentTypeInContext() {
        let sink = Test2Parser.EventSink(Test2Parser.Options())

        sink.setDocumentType("root", "pub", "sys")

        #expect(sink.context.documentType?.name == "root")
        #expect(sink.context.documentType?.publicID == "pub")
        #expect(sink.context.documentType?.systemID == "sys")
    }

    @Test
    func shouldAbort_reflectsContext() {
        let sink = Test2Parser.EventSink(Test2Parser.Options())

        #expect(!sink.shouldAbort)

        sink.startElement("unrecognized", nil, [])

        #expect(sink.shouldAbort)
    }

    @Test
    func startElement_buildsNestedElementInContext() throws {
        let sink = Test2Parser.EventSink(Test2Parser.Options())

        sink.startElement("root", nil, [])
        sink.startElement("child", nil, [])
        sink.endElement("child", nil)
        sink.endElement("root", nil)

        let node = try #require(sink.context.result.success)

        #expect(node.children?.first?.element == .child)
    }
}
