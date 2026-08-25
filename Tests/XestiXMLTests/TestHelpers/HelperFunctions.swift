// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
import Testing
@testable import XestiXML

//  Asserts that `source` is *not* well-formed XML, by recording the failure
//  `expectWellFormed(_:_:)` is expected to produce as a known issue.
func expectNotWellFormed(_ source: String,
                         sourceLocation: SourceLocation = #_sourceLocation) {
    withKnownIssue(sourceLocation: sourceLocation) {
        expectWellFormed(Data(source.utf8),
                         sourceLocation)
    }
}

//  Builds a `Test3Node` element carrying an optional `xml:space` attribute,
//  which is otherwise tedious to spell out at every call site.
func element(_ name: String,
             _ space: String?,
             _ children: [Test3Node]) -> Test3Node {
    var attributes: [Test3Attribute: String] = [:]

    if let space {
        attributes[Test3Attribute("space", "http://www.w3.org/XML/1998/namespace")] = space
    }

    return Test3Node(element: Test2Element(name, nil),
                     attributes: attributes,
                     children: children)
}

//  Formats a trivial document under the given namespace bindings, expecting the
//  bindings themselves to be rejected.
func formatFailure(_ namespaces: [Test2Formatter.Namespace]) throws -> Test2Formatter.Error? {
    let node = Test2Node(element: Test2Element("root", nil),
                         attributes: [:],
                         children: [])

    let options = Test2Formatter.Options(emitsXMLDeclaration: false,
                                         namespaces: namespaces)

    return #expect(throws: Test2Formatter.Error.self) {
        try Test2Formatter(options: options).format(XMLDocument(root: node))
    }
}

func formatted(_ node: TestNode,
               _ options: TestFormatter.Options = .init(emitsXMLDeclaration: false),
               sourceLocation: SourceLocation = #_sourceLocation) throws -> String {
    try text(TestFormatter(options: options).format(XMLDocument(root: node)),
             sourceLocation: sourceLocation)
}

func formatted(_ node: Test2Node,
               _ options: Test2Formatter.Options = .init(emitsXMLDeclaration: false),
               sourceLocation: SourceLocation = #_sourceLocation) throws -> String {
    try text(Test2Formatter(options: options).format(XMLDocument(root: node)),
             sourceLocation: sourceLocation)
}

func formatted(_ node: Test3Node,
               _ options: Test3Formatter.Options = .init(emitsXMLDeclaration: false),
               sourceLocation: SourceLocation = #_sourceLocation) throws -> String {
    try text(Test3Formatter(options: options).format(XMLDocument(root: node)),
             sourceLocation: sourceLocation)
}

func formattedIndented(_ node: TestNode,
                       _ indentation: Int = 2,
                       sourceLocation: SourceLocation = #_sourceLocation) throws -> String {
    let options = TestFormatter.Options(emitsXMLDeclaration: false,
                                        indentation: indentation)

    return try text(TestFormatter(options: options).format(XMLDocument(root: node)),
                    sourceLocation: sourceLocation)
}

func formatted(_ document: Test2Document,
               _ options: Test2Formatter.Options = .init(emitsXMLDeclaration: false),
               sourceLocation: SourceLocation = #_sourceLocation) throws -> String {
    try text(Test2Formatter(options: options).format(document),
             sourceLocation: sourceLocation)
}

//  Formats a document of one element around one text node, carrying the given
//  declaration, and hands back the bytes themselves — the encoding tests are
//  about the bytes, so decoding them here would defeat the purpose.
func formattedData(_ declaration: XMLDeclaration,
                   _ value: String,
                   _ emitsXMLDeclaration: Bool = true) throws -> Data {
    let document = Test2Document(declaration: declaration,
                                 root: Test2Node(element: .root,
                                                 attributes: [:],
                                                 children: [Test2Node(text: value)]))

    let options = Test2Formatter.Options(emitsXMLDeclaration: emitsXMLDeclaration)

    return try Test2Formatter(options: options).format(document)
}

//  Formats the same document as `formattedData(_:_:_:)`, expecting the encoding
//  it declares to defeat it.
func formattedDataFailure(_ declaration: XMLDeclaration,
                          _ value: String) throws -> Test2Formatter.Error? {
    #expect(throws: Test2Formatter.Error.self) {
        try formattedData(declaration,
                          value)
    }
}

func formattedIndented(_ node: Test3Node,
                       _ indentation: Int = 2,
                       sourceLocation: SourceLocation = #_sourceLocation) throws -> String {
    let options = Test3Formatter.Options(emitsXMLDeclaration: false,
                                         indentation: indentation)

    return try text(Test3Formatter(options: options).format(XMLDocument(root: node)),
                    sourceLocation: sourceLocation)
}

func parsedDocument(_ source: String,
                    _ options: Test2Parser.Options = .init()) throws -> Test2Document {
    try Test2Parser(options: options).parse(Data(source.utf8))
}

func parsedNode(_ source: String,
                _ options: Test3Parser.Options = .init()) throws -> Test3Node {
    try Test3Parser(options: options).parse(Data(source.utf8)).root
}

func roundTripped(_ source: String,
                  sourceLocation: SourceLocation = #_sourceLocation) throws -> String {
    let node = try Test2Parser().parse(Data(source.utf8)).root

    return try formatted(node,
                         sourceLocation: sourceLocation)
}

//  Parses and reformats an entire document, retaining everything the parser is
//  able to represent.
func roundTrippedDocument(_ source: String,
                          _ options: Test2Formatter.Options = .init(emitsXMLDeclaration: true),
                          sourceLocation: SourceLocation = #_sourceLocation) throws -> String {
    try formatted(parsedDocument(source),
                  options,
                  sourceLocation: sourceLocation)
}

//  Every formatter helper funnels its output through here, so this is where
//  each one is checked against libxml2 for well-formedness.
func text(_ data: Data,
          sourceLocation: SourceLocation = #_sourceLocation) throws -> String {
    expectWellFormed(data,
                     sourceLocation)

    return try #require(String(bytes: data,
                               encoding: .utf8),
                        sourceLocation: sourceLocation)
}
