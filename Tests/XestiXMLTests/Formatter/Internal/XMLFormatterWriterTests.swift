// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
import Testing
@testable import XestiXML

struct XMLFormatterWriterTests {
}

// MARK: -

extension XMLFormatterWriterTests {
    @Test
    func encodedText_emptyTextProducesEmptyData() throws {
        let writer = TestFormatter.Writer(TestFormatter.Options())

        #expect(try writer.encodedText().isEmpty)
    }

    @Test
    func encodedText_returnsUTF8Bytes() throws {
        var writer = TestFormatter.Writer(TestFormatter.Options(emitsXMLDeclaration: false))
        let node = TestNode(element: .root, attributes: [:], children: [])

        try writer.writeDocument(XMLDocument(root: node))

        #expect(try String(data: writer.encodedText(), encoding: .utf8) == writer.text)
    }

    @Test
    func init_defaultEncodingIsUTF8() {
        let writer = TestFormatter.Writer(TestFormatter.Options())

        #expect(writer.encoding == .utf8)
        #expect(writer.encodingName == "UTF-8")
        #expect(writer.text.isEmpty)
    }

    @Test
    func writeDocument_appliesIndentation() throws {
        var writer = TestFormatter.Writer(TestFormatter.Options(emitsXMLDeclaration: false, indentation: 2))
        let child = TestNode(element: .child, attributes: [:], children: [])
        let node = TestNode(element: .root, attributes: [:], children: [child])

        try writer.writeDocument(XMLDocument(root: node))

        #expect(writer.text.contains("\n  <child/>"))
    }

    @Test
    func writeDocument_omitsXMLDeclarationWhenDisabled() throws {
        var writer = TestFormatter.Writer(TestFormatter.Options(emitsXMLDeclaration: false))
        let node = TestNode(element: .root, attributes: [:], children: [])

        try writer.writeDocument(XMLDocument(root: node))

        #expect(!writer.text.contains("<?xml"))
    }

    @Test
    func writeDocument_stripsCommentsWhenOptionEnabled() throws {
        var writer = TestFormatter.Writer(TestFormatter.Options(emitsXMLDeclaration: false, stripsComments: true))
        let child = TestNode(comment: "note")
        let node = TestNode(element: .root, attributes: [:], children: [child])

        try writer.writeDocument(XMLDocument(root: node))

        #expect(!writer.text.contains("<!--"))
    }

    @Test
    func writeDocument_throwsForTextRootNode() {
        var writer = TestFormatter.Writer(TestFormatter.Options())
        let document = XMLDocument(root: TestNode(text: "hello"))

        #expect(throws: TestFormatter.Error.self) {
            try writer.writeDocument(document)
        }
    }

    @Test
    func writeDocument_throwsForUnsupportedEncoding() {
        var writer = Test2Formatter.Writer(Test2Formatter.Options())
        let node = Test2Node(element: .root, attributes: [:], children: [])
        let declaration = XMLDeclaration(encoding: "bogus-charset")
        let document = Test2Document(declaration: declaration, root: node)

        #expect(throws: Test2Formatter.Error.self) {
            try writer.writeDocument(document)
        }
    }

    @Test
    func writeDocument_updatesEncodingAfterDeclaration() throws {
        var writer = Test2Formatter.Writer(Test2Formatter.Options())
        let node = Test2Node(element: .root, attributes: [:], children: [])
        let declaration = XMLDeclaration(encoding: "ISO-8859-1")
        let document = Test2Document(declaration: declaration, root: node)

        try writer.writeDocument(document)

        #expect(writer.encoding == .isoLatin1)
        #expect(writer.encodingName == "ISO-8859-1")
    }

    @Test
    func writeDocument_writesDocumentType() throws {
        var writer = TestFormatter.Writer(TestFormatter.Options(emitsXMLDeclaration: false))
        let node = TestNode(element: .root, attributes: [:], children: [])
        let document = XMLDocument(documentType: XMLDocumentType(name: "root"), root: node)

        try writer.writeDocument(document)

        #expect(writer.text.contains("<!DOCTYPE root>"))
    }

    @Test
    func writeDocument_writesPrologAndEpilog() throws {
        var writer = TestFormatter.Writer(TestFormatter.Options(emitsXMLDeclaration: false))
        let node = TestNode(element: .root, attributes: [:], children: [])
        let document = XMLDocument(prolog: [TestNode(comment: "pre")],
                                   root: node,
                                   epilog: [TestNode(comment: "post")])

        try writer.writeDocument(document)

        let prologRange = try #require(writer.text.range(of: "<!--pre-->"))
        let rootRange = try #require(writer.text.range(of: "<root/>"))
        let epilogRange = try #require(writer.text.range(of: "<!--post-->"))

        #expect(prologRange.lowerBound < rootRange.lowerBound)
        #expect(rootRange.lowerBound < epilogRange.lowerBound)
    }

    @Test
    func writeDocument_writesXMLDeclarationWhenEnabled() throws {
        var writer = TestFormatter.Writer(TestFormatter.Options())
        let node = TestNode(element: .root, attributes: [:], children: [])

        try writer.writeDocument(XMLDocument(root: node))

        #expect(writer.text.hasPrefix("<?xml"))
    }
}
