// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
import Testing
@testable import XestiXML

private struct TestElement: XestiXML.XMLElement {
    let name: String
    let uri: String?

    init(_ name: String,
         _ uri: String?) {
        precondition(!name.isEmpty)

        self.name = name
        self.uri = uri
    }

    init?(name: String,
          uri: String?) {
        guard !name.isEmpty,
              ["child", "item", "name", "root", "value"].contains(name)
        else { return nil }

        self.name = name
        self.uri = uri
    }

    static func == (lhs: Self,
                    rhs: Self) -> Bool {
        lhs.name == rhs.name
    }

    static let child = Self("child", nil)
    static let item = Self("item", nil)
    static let root = Self("root", nil)
}

private enum TestAttribute: String, XestiXML.XMLAttribute {
    case id
    case name
    case type
}

struct XMLParserTests {
}

// MARK: -

extension XMLParserTests {
    @Test
    func test_parseCDATAContent() throws {
        let data = Data("<root><![CDATA[hello <world>]]></root>".utf8)
        let node = try XestiXML.XMLParser<TestElement, TestAttribute>().parse(data)

        #expect(node.value == "hello <world>")
    }

    @Test
    func test_parseElementWithAttributes() throws {
        let data = Data("<root id=\"1\" name=\"test\"/>".utf8)
        let node = try XestiXML.XMLParser<TestElement, TestAttribute>().parse(data)

        #expect(node.element == .root)
        #expect(node.attributes?[.id] == "1")
        #expect(node.attributes?[.name] == "test")
    }

    @Test
    func test_parseElementsWithTextAndChildren() throws {
        let data = Data("<root>text<child/>more</root>".utf8)
        let node = try XestiXML.XMLParser<TestElement, TestAttribute>().parse(data)

        #expect(node.children?.count == 3)
    }

    @Test
    func test_parseInvalidXML() {
        let data = Data("not xml at all".utf8)

        #expect(throws: XMLError.self) {
            try XestiXML.XMLParser<TestElement, TestAttribute>().parse(data)
        }
    }

    @Test
    func test_parseMalformedXML() {
        let data = Data("<root><".utf8)

        #expect(throws: XMLError.self) {
            try XestiXML.XMLParser<TestElement, TestAttribute>().parse(data)
        }
    }

    @Test
    func test_parseMixedContent() throws {
        let data = Data("<root><child>text1</child><item>text2</item></root>".utf8)
        let node = try XestiXML.XMLParser<TestElement, TestAttribute>().parse(data)

        #expect(node.children?.count == 2)
        #expect(node.firstChildElement(.child)?.value == "text1")
        #expect(node.firstChildElement(.item)?.value == "text2")
    }

    @Test
    func test_parseMultipleSiblings() throws {
        let data = Data("<root><child/><child/><child/></root>".utf8)
        let node = try XestiXML.XMLParser<TestElement, TestAttribute>().parse(data)

        #expect(node.allChildElements(.child).count == 3)
    }

    @Test
    func test_parseNestedElements() throws {
        let data = Data("<root><child><item/></child></root>".utf8)
        let node = try XestiXML.XMLParser<TestElement, TestAttribute>().parse(data)

        #expect(node.element == .root)
        #expect(node.children?.count == 1)
        #expect(node.children?.first?.element == .child)
        #expect(node.children?.first?.children?.first?.element == .item)
    }

    @Test
    func test_parseSimpleElement() throws {
        let data = Data("<root/>".utf8)
        let node = try XestiXML.XMLParser<TestElement, TestAttribute>().parse(data)

        #expect(node.element == .root)
        #expect(node.children?.isEmpty == true)
        #expect(node.attributes?.isEmpty == true)
    }

    @Test
    func test_parseTextContent() throws {
        let data = Data("<root>hello world</root>".utf8)
        let node = try XestiXML.XMLParser<TestElement, TestAttribute>().parse(data)

        #expect(node.value == "hello world")
    }

    @Test
    func test_parseUnrecognizedAttribute() {
        let data = Data("<root unknown=\"value\"/>".utf8)

        #expect(throws: XMLError.self) {
            try XestiXML.XMLParser<TestElement, TestAttribute>().parse(data)
        }
    }

    @Test
    func test_parseUnrecognizedElement() {
        let data = Data("<root><unknown/></root>".utf8)

        #expect(throws: XMLError.self) {
            try XestiXML.XMLParser<TestElement, TestAttribute>().parse(data)
        }
    }

    @Test
    func test_parseUnrecognizedRootElement() {
        let data = Data("<unknown/>".utf8)

        #expect(throws: XMLError.self) {
            try XestiXML.XMLParser<TestElement, TestAttribute>().parse(data)
        }
    }

    @Test
    func test_parseWhitespaceTextNormalized() throws {
        let data = Data("<root>  hello  world  </root>".utf8)
        let node = try XestiXML.XMLParser<TestElement, TestAttribute>().parse(data)

        #expect(node.value == "hello world")
    }
}
