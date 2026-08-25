// © 2026 John Gary Pusey (see LICENSE.md)

import XestiTools
@testable import XestiXML

typealias SRTestFormatter = XMLFormatter<SRTestElement, SRTestAttribute>
typealias SRTestNode      = XMLNode<SRTestElement, SRTestAttribute>
typealias Test2Document   = XMLDocument<Test2Element, TestAttribute>
typealias Test2Formatter  = XMLFormatter<Test2Element, TestAttribute>
typealias Test2Node       = XMLNode<Test2Element, TestAttribute>
typealias Test2Parser     = XMLParser<Test2Element, TestAttribute>
typealias Test3Formatter  = XMLFormatter<Test2Element, Test3Attribute>
typealias Test3Node       = XMLNode<Test2Element, Test3Attribute>
typealias Test3Parser     = XMLParser<Test2Element, Test3Attribute>
typealias TestFormatter   = XMLFormatter<TestElement, TestAttribute>
typealias TestNode        = XMLNode<TestElement, TestAttribute>
typealias TestParser      = XMLParser<TestElement, TestAttribute>

struct SRTestAttribute: XMLAttribute, StringRepresentable {
    let stringValue: String

    init?(stringValue: String) {
        guard Self.isValid(stringValue)
        else { return nil }

        self.stringValue = stringValue
    }
}

struct SRTestElement: XMLElement, StringRepresentable {
    let stringValue: String

    init?(stringValue: String) {
        guard Self.isValid(stringValue)
        else { return nil }

        self.stringValue = stringValue
    }
}

enum TestAttribute: String, XMLAttribute {
    case id
    case name
    case value
}

enum TestElement: String, XMLElement {
    case child
    case item
    case other
    case root
}

//  Accepts any non-empty attribute name, including qualified names such as
//  `a:id`.
struct Test3Attribute: XestiXML.XMLAttribute {
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
        guard !name.isEmpty
        else { return nil }

        self.name = name
        self.uri = uri
    }
}

struct Test2Element: XestiXML.XMLElement {
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
