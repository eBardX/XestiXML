// © 2026 John Gary Pusey (see LICENSE.md)

import XestiTools
@testable import XestiXML

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

struct TestElementExt: XestiXML.XMLElement {
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
