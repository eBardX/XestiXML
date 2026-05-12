// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
import Testing
@testable import XestiXML

struct XMLParserTests {
}

// MARK: -

extension XMLParserTests {
    @Test
    func test_parse_cdataContent() throws {
        let data = Data("<root><![CDATA[hello <world>]]></root>".utf8)
        let node = try XestiXML.XMLParser<TestElementExt, TestAttribute>().parse(data)

        #expect(node.value == "hello <world>")
    }

    @Test
    func test_parse_elementWithAttributes() throws {
        let data = Data("<root id=\"1\" name=\"test\"/>".utf8)
        let node = try XestiXML.XMLParser<TestElementExt, TestAttribute>().parse(data)

        #expect(node.element == .root)
        #expect(node.attributes?[.id] == "1")
        #expect(node.attributes?[.name] == "test")
    }

    @Test
    func test_parse_elementsWithTextAndChildren() throws {
        let data = Data("<root>text<child/>more</root>".utf8)
        let node = try XestiXML.XMLParser<TestElementExt, TestAttribute>().parse(data)

        #expect(node.children?.count == 3)
    }

    @Test
    func test_parse_invalidXML() {
        let data = Data("not xml at all".utf8)

        #expect(throws: XMLError.self) {
            try XestiXML.XMLParser<TestElementExt, TestAttribute>().parse(data)
        }
    }

    @Test
    func test_parse_malformedXML() {
        let data = Data("<root><".utf8)

        #expect(throws: XMLError.self) {
            try XestiXML.XMLParser<TestElementExt, TestAttribute>().parse(data)
        }
    }

    @Test
    func test_parse_mixedContent() throws {
        let data = Data("<root><child>text1</child><item>text2</item></root>".utf8)
        let node = try XestiXML.XMLParser<TestElementExt, TestAttribute>().parse(data)

        #expect(node.children?.count == 2)
        #expect(node.firstChildElement(.child)?.value == "text1")
        #expect(node.firstChildElement(.item)?.value == "text2")
    }

    @Test
    func test_parse_multipleSiblings() throws {
        let data = Data("<root><child/><child/><child/></root>".utf8)
        let node = try XestiXML.XMLParser<TestElementExt, TestAttribute>().parse(data)

        #expect(node.allChildElements(.child).count == 3)
    }

    @Test
    func test_parse_nestedElements() throws {
        let data = Data("<root><child><item/></child></root>".utf8)
        let node = try XestiXML.XMLParser<TestElementExt, TestAttribute>().parse(data)

        #expect(node.element == .root)
        #expect(node.children?.count == 1)
        #expect(node.children?.first?.element == .child)
        #expect(node.children?.first?.children?.first?.element == .item)
    }

    @Test
    func test_parse_simpleElement() throws {
        let data = Data("<root/>".utf8)
        let node = try XestiXML.XMLParser<TestElementExt, TestAttribute>().parse(data)

        #expect(node.element == .root)
        #expect(node.children?.isEmpty == true)
        #expect(node.attributes?.isEmpty == true)
    }

    @Test
    func test_parse_textContent() throws {
        let data = Data("<root>hello world</root>".utf8)
        let node = try XestiXML.XMLParser<TestElementExt, TestAttribute>().parse(data)

        #expect(node.value == "hello world")
    }

    @Test
    func test_parse_unrecognizedAttribute() {
        let data = Data("<root unknown=\"value\"/>".utf8)

        #expect(throws: XMLError.self) {
            try XestiXML.XMLParser<TestElementExt, TestAttribute>().parse(data)
        }
    }

    @Test
    func test_parse_unrecognizedElement() {
        let data = Data("<root><unknown/></root>".utf8)

        #expect(throws: XMLError.self) {
            try XestiXML.XMLParser<TestElementExt, TestAttribute>().parse(data)
        }
    }

    @Test
    func test_parse_simpleElement_rawRepresentable() throws {
        let data = Data("<root/>".utf8)
        let node = try XestiXML.XMLParser<TestElement, TestAttribute>().parse(data)

        #expect(node.element == .root)
    }

    @Test
    func test_parse_nestedElements_rawRepresentable() throws {
        let data = Data("<root><child/></root>".utf8)
        let node = try XestiXML.XMLParser<TestElement, TestAttribute>().parse(data)

        #expect(node.element == .root)
        #expect(node.children?.first?.element == .child)
    }

    @Test
    func test_parse_unrecognizedRootElement() {
        let data = Data("<unknown/>".utf8)

        #expect(throws: XMLError.self) {
            try XestiXML.XMLParser<TestElementExt, TestAttribute>().parse(data)
        }
    }

    @Test
    func test_parse_unrecognizedRootElement_reportsNilURIForNoNamespace() {
        let data = Data("<unknown/>".utf8)
        var capturedError: XMLError?

        do {
            _ = try XestiXML.XMLParser<TestElement, TestAttribute>().parse(data)
        } catch let error as XMLError {
            capturedError = error
        } catch {
        }

        if case let .unrecognizedElement(_, uri, _, _) = capturedError {
            #expect(uri == nil)
        } else {
            Issue.record("Expected unrecognizedElement error")
        }
    }

    @Test
    func test_parse_whitespaceTextNormalized() throws {
        let data = Data("<root>  hello  world  </root>".utf8)
        let node = try XestiXML.XMLParser<TestElementExt, TestAttribute>().parse(data)

        #expect(node.value == "hello world")
    }
}
