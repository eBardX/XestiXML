// © 2026 John Gary Pusey (see LICENSE.md)

import libxml2
import Testing
import XestiTools
@testable import XestiXML

struct XMLParserContextTests {
}

// MARK: -

extension XMLParserContextTests {
    @Test
    func appendComment_addsToEpilogAfterRoot() {
        var context = Test2Parser.Context(Test2Parser.Options())

        context.startElement("root", nil, [])
        context.endElement("root", nil)
        context.appendComment("note")

        #expect(context.epilog.first?.comment == "note")
    }

    @Test
    func appendComment_addsToPendingChildren() throws {
        var context = Test2Parser.Context(Test2Parser.Options())

        context.startElement("root", nil, [])
        context.appendComment("note")
        context.endElement("root", nil)

        let node = try #require(context.result.success)

        #expect(node.children?.first?.comment == "note")
    }

    @Test
    func appendComment_addsToProlog() {
        var context = Test2Parser.Context(Test2Parser.Options())

        context.appendComment("note")

        #expect(context.prolog.first?.comment == "note")
    }

    @Test
    func appendComment_ignoredDuringInternalSubset() {
        var context = Test2Parser.Context(Test2Parser.Options())

        context.setDocumentType("root", nil, nil)
        context.appendComment("note")

        #expect(context.prolog.isEmpty)
    }

    @Test
    func appendComment_strippedWhenOptionEnabled() {
        var context = Test2Parser.Context(Test2Parser.Options(stripsComments: true))

        context.appendComment("note")

        #expect(context.prolog.isEmpty)
    }

    @Test
    func appendProcessingInstruction_addsToPendingChildren() throws {
        var context = Test2Parser.Context(Test2Parser.Options())

        context.startElement("root", nil, [])
        context.appendProcessingInstruction("pi", "data")
        context.endElement("root", nil)

        let node = try #require(context.result.success)

        #expect(node.children?.first?.target == "pi")
    }

    @Test
    func appendProcessingInstruction_strippedWhenOptionEnabled() {
        var context = Test2Parser.Context(Test2Parser.Options(stripsProcessingInstructions: true))

        context.appendProcessingInstruction("pi", nil)

        #expect(context.prolog.isEmpty)
    }

    @Test
    func endElement_ignoredWhenNameMismatch() {
        var context = Test2Parser.Context(Test2Parser.Options())

        context.startElement("root", nil, [])
        context.endElement("other", nil)

        #expect(context.result.success == nil)
    }

    @Test
    func endElement_producesSuccessResultAtRoot() throws {
        var context = Test2Parser.Context(Test2Parser.Options())

        context.startElement("root", nil, [])
        context.endElement("root", nil)

        let node = try #require(context.result.success)

        #expect(node.element == .root)
    }

    @Test
    func endElement_restoresSavedContextForNestedElement() throws {
        var context = Test3Parser.Context(Test3Parser.Options())

        context.startElement("root", nil, [])
        context.startElement("child", nil, [])
        context.endElement("child", nil)
        context.appendText("after")
        context.endElement("root", nil)

        let node = try #require(context.result.success)

        #expect(node.children?.count == 2)
        #expect(node.children?.last?.value == "after")
    }

    @Test
    func flushText_discardsEmptyText() throws {
        var context = Test2Parser.Context(Test2Parser.Options())

        context.startElement("root", nil, [])
        context.flushText()
        context.endElement("root", nil)

        let node = try #require(context.result.success)

        #expect(node.children?.isEmpty == true)
    }

    @Test
    func flushText_normalizesWhitespaceByDefault() throws {
        var context = Test2Parser.Context(Test2Parser.Options())

        context.startElement("root", nil, [])
        context.appendText("  a   b  ")
        context.endElement("root", nil)

        let node = try #require(context.result.success)

        #expect(node.value == "a b")
    }

    @Test
    func flushText_preservesWhitespaceUnderXMLSpacePreserve() throws {
        var context = Test3Parser.Context(Test3Parser.Options())
        let spaceAttribute = SAXAttribute("space", "http://www.w3.org/XML/1998/namespace", "preserve")

        context.startElement("root", nil, [spaceAttribute])
        context.appendText("  a   b  ")
        context.endElement("root", nil)

        let node = try #require(context.result.success)

        #expect(node.value == "  a   b  ")
    }

    @Test
    func handleAbort_latchesGenericParseFailure() {
        var context = Test2Parser.Context(Test2Parser.Options())

        context.handleAbort(4, 8)

        guard case let .parseFailure(cause, line, column) = context.result.failure
        else {
            Issue.record("Expected parseFailure error")

            return
        }

        #expect(cause == nil)
        #expect(line == 4)
        #expect(column == 8)
    }

    @Test
    func handleAbort_latchesUnrecognizedAttributeError() {
        var context = Test2Parser.Context(Test2Parser.Options())

        context.startElement("root", nil, [SAXAttribute("bogus", nil, "1")])
        context.handleAbort(1, 10)

        guard case let .unrecognizedAttribute(name, _, _) = context.result.failure
        else {
            Issue.record("Expected unrecognizedAttribute error")

            return
        }

        #expect(name == "bogus")
    }

    @Test
    func handleAbort_latchesUnrecognizedElementError() {
        var context = Test2Parser.Context(Test2Parser.Options())

        context.startElement("unknown", nil, [])
        context.handleAbort(1, 1)

        guard case let .unrecognizedElement(name, _, _, _) = context.result.failure
        else {
            Issue.record("Expected unrecognizedElement error")

            return
        }

        #expect(name == "unknown")
    }

    @Test
    func handleError_ignoresAdvisoryDiagnostics() {
        var context = Test2Parser.Context(Test2Parser.Options())
        var xmlErr = xmlError()

        xmlErr.level = XML_ERR_WARNING

        context.handleError(LibXMLError(xmlErr))

        #expect(context.result.failure?.message == "Internal failure")
    }

    @Test
    func handleError_latchesFirstErrorOnly() {
        var context = Test2Parser.Context(Test2Parser.Options())
        var first = xmlError()
        var second = xmlError()

        first.level = XML_ERR_ERROR
        first.line = 1

        second.level = XML_ERR_ERROR
        second.line = 2

        context.handleError(LibXMLError(first))
        context.handleError(LibXMLError(second))

        guard case let .parseFailure(_, line, _) = context.result.failure
        else {
            Issue.record("Expected parseFailure error")

            return
        }

        #expect(line == 1)
    }

    @Test
    func init_defaultResultIsInternalFailure() {
        let context = Test2Parser.Context(Test2Parser.Options())

        #expect(context.result.failure?.message == "Internal failure")
    }

    @Test
    func setDeclaration_ignoresAbsentDeclaration() {
        var context = Test2Parser.Context(Test2Parser.Options())

        context.setDeclaration("1.0", nil, -1)

        #expect(context.declaration == nil)
    }

    @Test
    func setDeclaration_recordsPresentDeclaration() {
        var context = Test2Parser.Context(Test2Parser.Options())

        context.setDeclaration("1.0", "UTF-8", 0)

        #expect(context.declaration?.version == "1.0")
        #expect(context.declaration?.encoding == "UTF-8")
        #expect(context.declaration?.isStandalone == false)
    }

    @Test
    func setDocumentType_recordsDocumentType() {
        var context = Test2Parser.Context(Test2Parser.Options())

        context.setDocumentType("root", "pub", "sys")

        #expect(context.documentType?.name == "root")
        #expect(context.documentType?.publicID == "pub")
        #expect(context.documentType?.systemID == "sys")
    }

    @Test
    func setDocumentType_startsInternalSubset() {
        var context = Test2Parser.Context(Test2Parser.Options())

        context.setDocumentType("root", nil, nil)
        context.appendComment("note")

        //  A comment reported while the internal subset is open has nowhere to
        //  be represented, so it must be dropped.
        #expect(context.prolog.isEmpty)
    }

    //  Preservation is inherited by descendants only until a descendant asks
    //  for `xml:space="default"`; unlike the writer's indentation suppression,
    //  it is not a one-way latch.
    @Test
    func startElement_descendantCanDisablePreservation() throws {
        var context = Test3Parser.Context(Test3Parser.Options())
        let preserveAttribute = SAXAttribute("space", "http://www.w3.org/XML/1998/namespace", "preserve")
        let defaultAttribute = SAXAttribute("space", "http://www.w3.org/XML/1998/namespace", "default")

        context.startElement("root", nil, [preserveAttribute])
        context.startElement("child", nil, [defaultAttribute])
        context.appendText("  a   b  ")
        context.endElement("child", nil)
        context.appendText("  c   d  ")
        context.endElement("root", nil)

        let node = try #require(context.result.success)

        #expect(node.children?.first?.value == "a b")
        #expect(node.children?.last?.value == "  c   d  ")
    }

    @Test
    func startElement_flushesPendingTextOfEnclosingElement() throws {
        var context = Test3Parser.Context(Test3Parser.Options())

        context.startElement("root", nil, [])
        context.appendText("before")
        context.startElement("child", nil, [])
        context.endElement("child", nil)
        context.endElement("root", nil)

        let node = try #require(context.result.success)

        #expect(node.children?.first?.value == "before")
    }

    @Test
    func startElement_marksShouldAbortForUnrecognizedAttribute() {
        var context = Test2Parser.Context(Test2Parser.Options())

        context.startElement("root", nil, [SAXAttribute("bogus", nil, "1")])

        #expect(context.shouldAbort)
    }

    @Test
    func startElement_marksShouldAbortForUnrecognizedElement() {
        var context = Test2Parser.Context(Test2Parser.Options())

        context.startElement("unknown", nil, [])

        #expect(context.shouldAbort)
    }
}
