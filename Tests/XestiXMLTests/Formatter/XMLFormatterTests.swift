// © 2026 John Gary Pusey (see LICENSE.md)

//  Every test of `XMLFormatter` lives here, so that one source file maps to one
//  test file; the length that follows from it is not worth splitting the type's
//  tests across several files for.
// swiftlint:disable file_length

import Foundation
import Testing
import XestiTools
@testable import XestiXML

struct XMLFormatterTests {
}

// MARK: -

extension XMLFormatterTests {
    //  An unprefixed attribute name is in *no* namespace, never the default
    //  one, so an attribute needs a real prefix even when its URI is already
    //  serving as the default namespace for elements.
    @Test
    func format_attributeInDefaultNamespaceStillTakesPrefix() throws {
        let node = Test3Node(element: Test2Element("root", "urn:one"),
                             attributes: [Test3Attribute("id", "urn:one"): "1"],
                             children: [])

        #expect(try formatted(node) == "<root xmlns=\"urn:one\" xmlns:ns1=\"urn:one\" ns1:id=\"1\"/>")
    }

    @Test
    func format_attributeInNamespace() throws {
        let node = Test3Node(element: Test2Element("root", nil),
                             attributes: [Test3Attribute("id", "urn:a"): "1"],
                             children: [])

        #expect(try formatted(node) == "<root xmlns:ns1=\"urn:a\" ns1:id=\"1\"/>")
    }

    @Test
    func format_attributesDistinguishedByNamespace() throws {
        let node = Test3Node(element: Test2Element("root", nil),
                             attributes: [Test3Attribute("id", "urn:a"): "1",
                                          Test3Attribute("id", nil): "2"],
                             children: [])

        #expect(try formatted(node) == "<root xmlns:ns1=\"urn:a\" id=\"2\" ns1:id=\"1\"/>")
    }

    @Test
    func format_attributesSortedByName() throws {
        let node = TestNode(element: .root,
                            attributes: [.value: "3",
                                         .id: "1",
                                         .name: "2"],
                            children: [])

        #expect(try formatted(node) == "<root id=\"1\" name=\"2\" value=\"3\"/>")
    }

    //  A binding with a `nil` prefix is how a caller asks for a default
    //  namespace that the tree would not otherwise be given one for.
    @Test
    func format_boundDefaultFromOptions() throws {
        let node = Test2Node(element: Test2Element("root", "urn:one"),
                             attributes: [:],
                             children: [Test2Node(element: Test2Element("child", "urn:two"),
                                                  attributes: [:],
                                                  children: [])])

        let options = Test2Formatter.Options(emitsXMLDeclaration: false,
                                             namespaces: [.init(prefix: nil,
                                                                uri: "urn:two")])

        #expect(try formatted(node, options) == "<ns1:root xmlns=\"urn:two\" xmlns:ns1=\"urn:one\">"
                                                + "<child/></ns1:root>")
    }

    @Test
    func format_boundPrefixFromOptions() throws {
        let node = Test2Node(element: Test2Element("root", "urn:one"),
                             attributes: [:],
                             children: [Test2Node(element: Test2Element("child", "urn:one"),
                                                  attributes: [:],
                                                  children: [])])

        let options = Test2Formatter.Options(emitsXMLDeclaration: false,
                                             namespaces: [.init(prefix: "a",
                                                                uri: "urn:one")])

        #expect(try formatted(node, options) == "<a:root xmlns:a=\"urn:one\"><a:child/></a:root>")
    }

    @Test
    func format_comment() throws {
        let node = Test2Node(element: .root,
                             attributes: [:],
                             children: [Test2Node(comment: " note ")])

        #expect(try formatted(node) == "<root><!-- note --></root>")
    }

    @Test
    func format_declaresDefaultNamespace() throws {
        let node = Test2Node(element: Test2Element("root", "urn:one"),
                             attributes: [:],
                             children: [Test2Node(element: Test2Element("child", "urn:one"),
                                                  attributes: [:],
                                                  children: [])])

        #expect(try formatted(node) == "<root xmlns=\"urn:one\"><child/></root>")
    }

    //  Every listed binding is declared, whether or not the tree uses it, so
    //  that the output of a given set of options is predictable.
    @Test
    func format_declaresUnusedBinding() throws {
        let node = Test2Node(element: Test2Element("root", nil),
                             attributes: [:],
                             children: [])

        let options = Test2Formatter.Options(emitsXMLDeclaration: false,
                                             namespaces: [.init(prefix: "unused",
                                                                uri: "urn:unused")])

        #expect(try formatted(node, options) == "<root xmlns:unused=\"urn:unused\"/>")
    }

    @Test
    func format_documentDeclaration() throws {
        let decl = XMLDeclaration(version: "1.0",
                                  encoding: "UTF-8",
                                  isStandalone: false)

        let document = Test2Document(declaration: decl,
                                     root: Test2Node(element: .root,
                                                     attributes: [:],
                                                     children: []))

        let options = Test2Formatter.Options(emitsXMLDeclaration: true)

        #expect(try formatted(document, options)
            == "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?><root/>")
    }

    //  What a declaration leaves out, the XML specification supplies on the
    //  reader's behalf, so writing it out changes nothing about what the
    //  document says — only how much the reader has to know to agree.
    @Test
    func format_documentDeclarationCompleted() throws {
        let document = Test2Document(declaration: XMLDeclaration(version: "1.0"),
                                     root: Test2Node(element: .root,
                                                     attributes: [:],
                                                     children: []))

        let options = Test2Formatter.Options(emitsXMLDeclaration: true)

        #expect(try formatted(document, options)
            == "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?><root/>")
    }

    //  Completing a declaration must not overwrite what it does say: `yes` is a
    //  claim about the document that only its author can make.
    @Test
    func format_documentDeclarationStandaloneYes() throws {
        let document = Test2Document(declaration: XMLDeclaration(version: "1.0",
                                                                 isStandalone: true),
                                     root: Test2Node(element: .root,
                                                     attributes: [:],
                                                     children: []))

        let options = Test2Formatter.Options(emitsXMLDeclaration: true)

        #expect(try formatted(document, options)
            == "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?><root/>")
    }

    @Test
    func format_documentDeclarationSuppressed() throws {
        let document = Test2Document(declaration: XMLDeclaration(version: "1.0"),
                                     root: Test2Node(element: .root,
                                                     attributes: [:],
                                                     children: []))

        #expect(try formatted(document) == "<root/>")
    }

    @Test
    func format_documentInvalidVersionThrows() {
        let document = Test2Document(declaration: XMLDeclaration(version: "banana"),
                                     root: Test2Node(element: .root,
                                                     attributes: [:],
                                                     children: []))

        let options = Test2Formatter.Options(emitsXMLDeclaration: true)

        #expect(throws: Test2Formatter.Error.self) {
            try formatted(document, options)
        }
    }

    @Test
    func format_documentPrologAndEpilog() throws {
        let document = Test2Document(prolog: [Test2Node(comment: " before ")],
                                     root: Test2Node(element: .root,
                                                     attributes: [:],
                                                     children: []),
                                     epilog: [Test2Node(processingInstruction: "after")])

        #expect(try formatted(document) == "<!-- before --><root/><?after?>")
    }

    @Test
    func format_documentTypeBare() throws {
        let document = Test2Document(documentType: XMLDocumentType(name: "root"),
                                     root: Test2Node(element: .root,
                                                     attributes: [:],
                                                     children: []))

        #expect(try formatted(document) == "<!DOCTYPE root><root/>")
    }

    @Test
    func format_documentTypePublic() throws {
        let docType = XMLDocumentType(name: "root",
                                      publicID: "-//X//DTD X//EN",
                                      systemID: "x.dtd")

        let document = Test2Document(documentType: docType,
                                     root: Test2Node(element: .root,
                                                     attributes: [:],
                                                     children: []))

        #expect(try formatted(document) == "<!DOCTYPE root PUBLIC \"-//X//DTD X//EN\" \"x.dtd\"><root/>")
    }

    //  A public identifier is meaningful only alongside a system identifier.
    @Test
    func format_documentTypePublicWithoutSystemThrows() {
        let document = Test2Document(documentType: XMLDocumentType(name: "root",
                                                                   publicID: "-//X//DTD X//EN"),
                                     root: Test2Node(element: .root,
                                                     attributes: [:],
                                                     children: []))

        #expect(throws: Test2Formatter.Error.self) {
            try formatted(document)
        }
    }

    @Test
    func format_documentTypeSystem() throws {
        let document = Test2Document(documentType: XMLDocumentType(name: "root",
                                                                   systemID: "x.dtd"),
                                     root: Test2Node(element: .root,
                                                     attributes: [:],
                                                     children: []))

        #expect(try formatted(document) == "<!DOCTYPE root SYSTEM \"x.dtd\"><root/>")
    }

    @Test
    func format_documentTypeSystemIDContainingQuote() throws {
        let document = Test2Document(documentType: XMLDocumentType(name: "root",
                                                                   systemID: "a\"b.dtd"),
                                     root: Test2Node(element: .root,
                                                     attributes: [:],
                                                     children: []))

        #expect(try formatted(document) == "<!DOCTYPE root SYSTEM 'a\"b.dtd'><root/>")
    }

    @Test
    func format_documentUnexpectedNodeOutsideRootElementThrows() {
        let document = Test2Document(prolog: [Test2Node(text: "nope")],
                                     root: Test2Node(element: .root,
                                                     attributes: [:],
                                                     children: []))

        #expect(throws: Test2Formatter.Error.self) {
            try formatted(document)
        }
    }

    //  A document with no declaration of its own still gets the default one.
    @Test
    func format_documentWithoutDeclaration() throws {
        let document = Test2Document(root: Test2Node(element: .root,
                                                     attributes: [:],
                                                     children: []))

        let options = Test2Formatter.Options(emitsXMLDeclaration: true)

        #expect(try formatted(document, options) == "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?><root/>")
    }

    //  Indentation inside a preserved element would insert whitespace the
    //  document asked to be left alone, even where no text node is present to
    //  make the mixed-content check fire.
    @Test
    func format_doesNotIndentInsidePreserve() throws {
        let node = element("root",
                           "preserve",
                           [element("child", nil, [])])

        #expect(try formattedIndented(node) == "<root xml:space=\"preserve\"><child/></root>\n")
    }

    @Test
    func format_emitsXMLDeclaration() throws {
        let node = TestNode(element: .root,
                            attributes: [:],
                            children: [])

        let options = TestFormatter.Options(emitsXMLDeclaration: true)

        #expect(try formatted(node, options) == "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?><root/>")
    }

    @Test
    func format_emptyElement() throws {
        let node = TestNode(element: .root,
                            attributes: [:],
                            children: [])

        #expect(try formatted(node) == "<root/>")
    }

    //  The encoding is resolved by IANA charset name, so the aliases under which
    //  a document may spell it are the ones every other reader accepts.
    @Test
    func format_encodingAlias() throws {
        let data = try formattedData(XMLDeclaration(version: "1.0",
                                                    encoding: "latin1"),
                                     "café")

        #expect(String(bytes: data, encoding: .isoLatin1)
            == "<?xml version=\"1.0\" encoding=\"latin1\" standalone=\"no\"?><root>café</root>")
    }

    //  An attribute value is one of the two places a character reference may be
    //  written, so a value survives an encoding that has never heard of it.
    @Test
    func format_encodingEscapesUnrepresentableAttributeValue() throws {
        let document = Test2Document(declaration: XMLDeclaration(version: "1.0",
                                                                 encoding: "US-ASCII"),
                                     root: Test2Node(element: .root,
                                                     attributes: [.name: "café"],
                                                     children: []))

        let options = Test2Formatter.Options(emitsXMLDeclaration: true)

        let data = try Test2Formatter(options: options).format(document)

        #expect(String(bytes: data, encoding: .ascii)
            == "<?xml version=\"1.0\" encoding=\"US-ASCII\" standalone=\"no\"?><root name=\"caf&#xe9;\"/>")

        expectWellFormed(data,
                         #_sourceLocation)
    }

    //  Text is the other, and the reference is read back as the character it
    //  names, so nothing about the document is lost by writing it in ASCII.
    @Test
    func format_encodingEscapesUnrepresentableText() throws {
        let data = try formattedData(XMLDeclaration(version: "1.0",
                                                    encoding: "US-ASCII"),
                                     "café")

        #expect(String(bytes: data, encoding: .ascii)
            == "<?xml version=\"1.0\" encoding=\"US-ASCII\" standalone=\"no\"?><root>caf&#xe9;</root>")

        expectWellFormed(data,
                         #_sourceLocation)

        let node = try Test2Parser().parse(data).root

        #expect(try formatted(node) == "<root>café</root>")
    }

    //  A declaration that is not emitted cannot tell a reader how to decode the
    //  bytes, so the encoding it names is not the one they are written in.
    @Test
    func format_encodingIgnoredWhenDeclarationSuppressed() throws {
        let data = try formattedData(XMLDeclaration(version: "1.0",
                                                    encoding: "ISO-8859-1"),
                                     "café",
                                     false)

        #expect(String(bytes: data, encoding: .utf8) == "<root>café</root>")
    }

    @Test
    func format_encodingISOLatin1() throws {
        let data = try formattedData(XMLDeclaration(version: "1.0",
                                                    encoding: "ISO-8859-1"),
                                     "café")

        #expect(String(bytes: data, encoding: .isoLatin1)
            == "<?xml version=\"1.0\" encoding=\"ISO-8859-1\" standalone=\"no\"?><root>café</root>")

        //  The single byte is the whole point: in UTF-8 the same character would
        //  be the two bytes 0xC3 0xA9.
        #expect(data.contains(0xe9))
        #expect(!data.contains(0xc3))

        expectWellFormed(data,
                         #_sourceLocation)
    }

    //  What the formatter writes in ISO 8859-1, the parser reads back as the
    //  same characters — which is the only thing the encoding is for.
    @Test
    func format_encodingISOLatin1RoundTrips() throws {
        let data = try formattedData(XMLDeclaration(version: "1.0",
                                                    encoding: "ISO-8859-1"),
                                     "café")

        let node = try Test2Parser().parse(data).root

        #expect(try formatted(node) == "<root>café</root>")
    }

    //  Whatever the formatter writes, the parser must be able to read — the two
    //  halves of the library disagreeing about a document is the one failure no
    //  encoding is worth.
    @Test
    func format_encodingRoundTripsThroughParser() throws {
        for name in ["UTF-8",
                     "UTF-16",
                     "UTF-16BE",
                     "UTF-16LE",
                     "ISO-8859-1",
                     "ISO-8859-15",
                     "windows-1252",
                     "macintosh",
                     //
                     //  None of these can carry an é, so each of them exercises
                     //  the character reference as well as the encoding.
                     //
                     "US-ASCII",
                     "ISO-8859-5",
                     "KOI8-R",
                     "Shift_JIS"] {
            let data = try formattedData(XMLDeclaration(version: "1.0",
                                                        encoding: name),
                                         "café")

            expectWellFormed(data,
                             #_sourceLocation)

            let node = try Test2Parser().parse(data).root

            #expect(try formatted(node) == "<root>café</root>",
                    "round trip through \(name)")
        }
    }

    //  A character reference inside a comment would be read as the characters
    //  that spell it, so a comment the encoding cannot carry cannot be written.
    @Test
    func format_encodingUnrepresentableCommentThrows() throws {
        let document = Test2Document(declaration: XMLDeclaration(version: "1.0",
                                                                 encoding: "US-ASCII"),
                                     prolog: [Test2Node(comment: " café ")],
                                     root: Test2Node(element: .root,
                                                     attributes: [:],
                                                     children: []))

        let options = Test2Formatter.Options(emitsXMLDeclaration: true)

        let error = #expect(throws: Test2Formatter.Error.self) {
            try Test2Formatter(options: options).format(document)
        }

        #expect(error?.message == "Cannot encode “ café ” in US-ASCII")
    }

    @Test
    func format_encodingUnrepresentableElementNameThrows() throws {
        let document = Test2Document(declaration: XMLDeclaration(version: "1.0",
                                                                 encoding: "US-ASCII"),
                                     root: Test2Node(element: Test2Element("café", nil),
                                                     attributes: [:],
                                                     children: []))

        let options = Test2Formatter.Options(emitsXMLDeclaration: true)

        let error = #expect(throws: Test2Formatter.Error.self) {
            try Test2Formatter(options: options).format(document)
        }

        #expect(error?.message == "Cannot encode “café” in US-ASCII")
    }

    //  A prefix from the options is written as part of every name it qualifies,
    //  and so is held to the same standard as the names themselves — the first
    //  of which is the root element, reported here in full.
    @Test
    func format_encodingUnrepresentableNamespacePrefixThrows() throws {
        let document = Test2Document(declaration: XMLDeclaration(version: "1.0",
                                                                 encoding: "US-ASCII"),
                                     root: Test2Node(element: Test2Element("root", "urn:one"),
                                                     attributes: [:],
                                                     children: []))

        let options = Test2Formatter.Options(emitsXMLDeclaration: true,
                                             namespaces: [.init(prefix: "café",
                                                                uri: "urn:one")])

        let error = #expect(throws: Test2Formatter.Error.self) {
            try Test2Formatter(options: options).format(document)
        }

        #expect(error?.message == "Cannot encode “café:root” in US-ASCII")
    }

    @Test
    func format_encodingUnrepresentableProcessingInstructionThrows() throws {
        let document = Test2Document(declaration: XMLDeclaration(version: "1.0",
                                                                 encoding: "US-ASCII"),
                                     root: Test2Node(element: .root,
                                                     attributes: [:],
                                                     children: []),
                                     epilog: [Test2Node(processingInstruction: "note",
                                                        data: "café")])

        let options = Test2Formatter.Options(emitsXMLDeclaration: true)

        let error = #expect(throws: Test2Formatter.Error.self) {
            try Test2Formatter(options: options).format(document)
        }

        #expect(error?.message == "Cannot encode “café” in US-ASCII")
    }

    @Test
    func format_encodingUnsupportedThrows() throws {
        let error = try formattedDataFailure(XMLDeclaration(version: "1.0",
                                                            encoding: "no-such-charset"),
                                             "plain")

        #expect(error?.message == "Unsupported character encoding: no-such-charset")
    }

    @Test
    func format_encodingUTF16() throws {
        let data = try formattedData(XMLDeclaration(version: "1.0",
                                                    encoding: "UTF-16"),
                                     "café")

        #expect(String(bytes: data, encoding: .utf16)
            == "<?xml version=\"1.0\" encoding=\"UTF-16\" standalone=\"no\"?><root>café</root>")

        //  A UTF-16 document is required to carry a byte order mark.
        #expect(data.starts(with: [0xff, 0xfe]) || data.starts(with: [0xfe, 0xff]))

        expectWellFormed(data,
                         #_sourceLocation)
    }

    //  A UTF-32 document opens with a byte order mark that begins with a UTF-16
    //  byte order mark, and is read as UTF-16 by the parsers that meet it. The
    //  big-endian variant escapes that fate, but not by anything a caller could
    //  rely on, so the family is refused entire.
    @Test
    func format_encodingUTF32Throws() throws {
        for name in ["UTF-32", "UTF-32BE", "UTF-32LE"] {
            let error = try formattedDataFailure(XMLDeclaration(version: "1.0",
                                                                encoding: name),
                                                 "café")

            #expect(error?.message == "Unsupported character encoding: \(name)")
        }
    }

    @Test
    func format_escapesAttributeValue() throws {
        let node = TestNode(element: .root,
                            attributes: [.name: "a<b>&c\"d\te\nf\rg"],
                            children: [])

        #expect(try formatted(node) == "<root name=\"a&lt;b&gt;&amp;c&quot;d&#x9;e&#xa;f&#xd;g\"/>")
    }

    @Test
    func format_escapesText() throws {
        let node = TestNode(element: .root,
                            attributes: [:],
                            children: [TestNode(text: "a<b>&c\"d")])

        #expect(try formatted(node) == "<root>a&lt;b&gt;&amp;c\"d</root>")
    }

    //  A generated prefix must not collide with one the caller bound, however
    //  much the generated one looks like it was meant to.
    @Test
    func format_generatedPrefixAvoidsBoundPrefix() throws {
        let node = Test2Node(element: Test2Element("root", "urn:one"),
                             attributes: [:],
                             children: [Test2Node(element: Test2Element("child", "urn:two"),
                                                  attributes: [:],
                                                  children: [])])

        let options = Test2Formatter.Options(emitsXMLDeclaration: false,
                                             namespaces: [.init(prefix: "ns1",
                                                                uri: "urn:two")])

        #expect(try formatted(node, options) == "<ns2:root xmlns:ns1=\"urn:two\" xmlns:ns2=\"urn:one\">"
                                                + "<ns1:child/></ns2:root>")
    }

    //  Prefix numbering follows document order, not the order the URIs happen
    //  to hash into.
    @Test
    func format_generatedPrefixesFollowDocumentOrder() throws {
        let node = Test2Node(element: Test2Element("root", nil),
                             attributes: [:],
                             children: [Test2Node(element: Test2Element("child", "urn:first"),
                                                  attributes: [:],
                                                  children: []),
                                        Test2Node(element: Test2Element("item", "urn:second"),
                                                  attributes: [:],
                                                  children: [])])

        #expect(try formatted(node) == "<root xmlns:ns1=\"urn:first\" xmlns:ns2=\"urn:second\">"
                                       + "<ns1:child/><ns2:item/></root>")
    }

    @Test
    func format_indentsByDefault() throws {
        let node = element("root",
                           nil,
                           [element("child", nil, [])])

        #expect(try formattedIndented(node) == "<root>\n  <child/>\n</root>\n")
    }

    @Test
    func format_indentsNestedElements() throws {
        let node = TestNode(element: .root,
                            attributes: [:],
                            children: [TestNode(element: .item,
                                                attributes: [:],
                                                children: [TestNode(element: .child,
                                                                    attributes: [:],
                                                                    children: [])]),
                                       TestNode(element: .item,
                                                attributes: [:],
                                                children: [])])

        let expected = """
                       <root>
                         <item>
                           <child/>
                         </item>
                         <item/>
                       </root>

                       """

        #expect(try formattedIndented(node) == expected)
    }

    @Test
    func format_indentsWithFourSpaces() throws {
        let node = TestNode(element: .root,
                            attributes: [:],
                            children: [TestNode(element: .item,
                                                attributes: [:],
                                                children: [])])

        #expect(try formattedIndented(node, 4) == "<root>\n    <item/>\n</root>\n")
    }

    @Test
    func format_invalidCommentDoubleHyphenThrows() {
        let node = Test2Node(element: .root,
                             attributes: [:],
                             children: [Test2Node(comment: "a -- b")])

        #expect(throws: Test2Formatter.Error.self) {
            try formatted(node)
        }
    }

    @Test
    func format_invalidCommentTrailingHyphenThrows() {
        let node = Test2Node(element: .root,
                             attributes: [:],
                             children: [Test2Node(comment: "a-")])

        #expect(throws: Test2Formatter.Error.self) {
            try formatted(node)
        }
    }

    @Test
    func format_invalidProcessingInstructionDataThrows() {
        let node = Test2Node(element: .root,
                             attributes: [:],
                             children: [Test2Node(processingInstruction: "pi",
                                                  data: "a ?> b")])

        #expect(throws: Test2Formatter.Error.self) {
            try formatted(node)
        }
    }

    @Test
    func format_nestedElements() throws {
        let node = TestNode(element: .root,
                            attributes: [:],
                            children: [TestNode(element: .child,
                                                attributes: [.id: "1"],
                                                children: [TestNode(text: "one")]),
                                       TestNode(element: .child,
                                                attributes: [.id: "2"],
                                                children: [])])

        #expect(try formatted(node) == "<root><child id=\"1\">one</child><child id=\"2\"/></root>")
    }

    @Test
    func format_neverIndentsMixedContent() throws {
        let node = TestNode(element: .root,
                            attributes: [:],
                            children: [TestNode(element: .item,
                                                attributes: [:],
                                                children: [TestNode(text: "one"),
                                                           TestNode(element: .child,
                                                                    attributes: [:],
                                                                    children: [TestNode(text: "two")]),
                                                           TestNode(text: "three")])])

        let expected = """
                       <root>
                         <item>one<child>two</child>three</item>
                       </root>

                       """

        #expect(try formattedIndented(node) == expected)
    }

    @Test
    func format_prefixesNestedNamespaces() throws {
        let node = Test2Node(element: Test2Element("root", "urn:one"),
                             attributes: [:],
                             children: [Test2Node(element: Test2Element("child", "urn:two"),
                                                  attributes: [:],
                                                  children: [Test2Node(element: Test2Element("item", "urn:one"),
                                                                       attributes: [:],
                                                                       children: [])])])

        #expect(try formatted(node) == "<ns1:root xmlns:ns1=\"urn:one\" xmlns:ns2=\"urn:two\">"
                                       + "<ns2:child>"
                                       + "<ns1:item/>"
                                       + "</ns2:child></ns1:root>")
    }

    @Test
    func format_prefixesSiblingNamespaces() throws {
        let node = Test2Node(element: Test2Element("root", "urn:one"),
                             attributes: [:],
                             children: [Test2Node(element: Test2Element("child", "urn:two"),
                                                  attributes: [:],
                                                  children: []),
                                        Test2Node(element: Test2Element("child", "urn:one"),
                                                  attributes: [:],
                                                  children: [])])

        #expect(try formatted(node) == "<ns1:root xmlns:ns1=\"urn:one\" xmlns:ns2=\"urn:two\">"
                                       + "<ns2:child/>"
                                       + "<ns1:child/></ns1:root>")
    }

    @Test
    func format_prefixesWhenSomeElementsAreUnnamespaced() throws {
        let node = Test2Node(element: Test2Element("root", "urn:one"),
                             attributes: [:],
                             children: [Test2Node(element: Test2Element("child", nil),
                                                  attributes: [:],
                                                  children: [])])

        #expect(try formatted(node) == "<ns1:root xmlns:ns1=\"urn:one\"><child/></ns1:root>")
    }

    @Test
    func format_preserveIsInheritedByDescendants() throws {
        let node = element("root",
                           "preserve",
                           [element("item",
                                    nil,
                                    [element("child", nil, [])])])

        #expect(try formattedIndented(node) == "<root xml:space=\"preserve\"><item><child/></item></root>\n")
    }

    @Test
    func format_processingInstruction() throws {
        let node = Test2Node(element: .root,
                             attributes: [:],
                             children: [Test2Node(processingInstruction: "xml-stylesheet",
                                                  data: "href=\"a.xsl\"")])

        #expect(try formatted(node) == "<root><?xml-stylesheet href=\"a.xsl\"?></root>")
    }

    @Test
    func format_processingInstructionWithoutData() throws {
        let node = Test2Node(element: .root,
                             attributes: [:],
                             children: [Test2Node(processingInstruction: "bare")])

        #expect(try formatted(node) == "<root><?bare?></root>")
    }

    @Test
    func format_rejectsDuplicateBoundPrefix() throws {
        let error = try formatFailure([.init(prefix: "a", uri: "urn:one"),
                                       .init(prefix: "a", uri: "urn:two")])

        #expect(error?.message == "Invalid namespace declaration: xmlns:a=“urn:two”")
    }

    @Test
    func format_rejectsDuplicateBoundURI() throws {
        let error = try formatFailure([.init(prefix: "a", uri: "urn:one"),
                                       .init(prefix: "b", uri: "urn:one")])

        #expect(error?.message == "Invalid namespace declaration: xmlns:b=“urn:one”")
    }

    @Test
    func format_rejectsEmptyBoundURI() throws {
        let error = try formatFailure([.init(prefix: "a", uri: "")])

        #expect(error?.message == "Invalid namespace declaration: xmlns:a=“”")
    }

    @Test
    func format_rejectsInvalidAttributeName() throws {
        let node = SRTestNode(element: SRTestElement("root"),
                              attributes: [SRTestAttribute("not a name"): "1"],
                              children: [])

        let error = #expect(throws: SRTestFormatter.Error.self) {
            try SRTestFormatter().format(XMLDocument(root: node))
        }

        #expect(error?.message == "Invalid attribute name: not a name")
    }

    @Test
    func format_rejectsInvalidElementName() throws {
        let node = SRTestNode(element: SRTestElement("2bad"),
                              attributes: [:],
                              children: [])

        let error = #expect(throws: SRTestFormatter.Error.self) {
            try SRTestFormatter().format(XMLDocument(root: node))
        }

        #expect(error?.message == "Invalid element name: 2bad")
    }

    @Test
    func format_rejectsInvalidTextValue() throws {
        let node = TestNode(element: .root,
                            attributes: [:],
                            children: [TestNode(text: "a\u{0}b")])

        let error = #expect(throws: TestFormatter.Error.self) {
            try TestFormatter().format(XMLDocument(root: node))
        }

        #expect(error?.message == "Invalid text value: “a\u{0}b”")
    }

    @Test
    func format_rejectsPrefixContainingColon() throws {
        let error = try formatFailure([.init(prefix: "a:b", uri: "urn:one")])

        #expect(error?.message == "Invalid namespace declaration: xmlns:a:b=“urn:one”")
    }

    @Test
    func format_rejectsRebindingXMLPrefix() throws {
        let error = try formatFailure([.init(prefix: "xml", uri: "urn:one")])

        #expect(error?.message == "Invalid namespace declaration: xmlns:xml=“urn:one”")
    }

    @Test
    func format_rejectsReservedAttributeName() throws {
        let node = SRTestNode(element: SRTestElement("root"),
                              attributes: [SRTestAttribute("xmlns:foo"): "urn:foo"],
                              children: [])

        let error = #expect(throws: SRTestFormatter.Error.self) {
            try SRTestFormatter().format(XMLDocument(root: node))
        }

        #expect(error?.message == "Reserved attribute name: xmlns:foo")
    }

    @Test
    func format_rejectsRootTextNode() throws {
        let error = #expect(throws: TestFormatter.Error.self) {
            try TestFormatter().format(XMLDocument(root: TestNode(text: "oops")))
        }

        #expect(error?.message == "Unexpected text node as root of XML node tree")
    }

    @Test
    func format_rejectsSecondBoundDefault() throws {
        let error = try formatFailure([.init(prefix: nil, uri: "urn:one"),
                                       .init(prefix: nil, uri: "urn:two")])

        #expect(error?.message == "Invalid namespace declaration: xmlns=“urn:two”")
    }

    @Test
    func format_rejectsXMLNSNamespaceURI() throws {
        let error = try formatFailure([.init(prefix: "a", uri: "http://www.w3.org/2000/xmlns/")])

        #expect(error?.message == "Invalid namespace declaration: xmlns:a=“http://www.w3.org/2000/xmlns/”")
    }

    //  The target `xml` is reserved in every combination of case.
    @Test
    func format_reservedProcessingInstructionTargetThrows() throws {
        for target in ["xml", "XML", "xMl"] {
            let node = Test2Node(element: .root,
                                 attributes: [:],
                                 children: [Test2Node(processingInstruction: target,
                                                      data: "version=\"1.0\"")])

            #expect(throws: Test2Formatter.Error.self) {
                try formatted(node)
            }
        }
    }

    @Test
    func format_returnsUTF8Data() throws {
        let node = Test2Node(element: .root,
                             attributes: [:],
                             children: [Test2Node(text: "café")])

        let data = try Test2Formatter().format(XMLDocument(root: node))

        #expect(try text(data) == "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?><root>café</root>")
    }

    @Test
    func format_sharedFormatterAcrossConcurrentTasks() async throws {
        let formatter = TestFormatter(options: .pretty)
        let nodes = (0..<64).map { index in
            TestNode(element: .root,
                     attributes: [.id: "\(index)"],
                     children: [TestNode(element: .item,
                                         attributes: [:],
                                         children: [TestNode(text: "value \(index)")])])
        }

        let results = await withTaskGroup(of: (Int, Data).self) { group in
            for (index, node) in nodes.enumerated() {
                group.addTask {
                    (index, (try? formatter.format(XMLDocument(root: node))) ?? Data())
                }
            }

            return await group.reduce(into: [Int: Data]()) { $0[$1.0] = $1.1 }
        }

        for (index, node) in nodes.enumerated() {
            #expect(try results[index] == formatter.format(XMLDocument(root: node)))
        }
    }

    //  Stripping happens before any line break is written, so a stripped child
    //  must not leave an indented blank line behind.
    @Test
    func format_strippedChildLeavesNoBlankLine() throws {
        let source = "<root><!-- note --><child>x</child></root>"
        let options = Test2Formatter.Options(emitsXMLDeclaration: false,
                                             indentation: 4,
                                             stripsComments: true)

        let expected = """
                       <root>
                           <child>x</child>
                       </root>

                       """

        #expect(try roundTrippedDocument(source, options) == expected)
    }

    //  A stripped node is never written, so it is never validated either.
    @Test
    func format_strippedInvalidCommentDoesNotThrow() throws {
        let options = Test2Formatter.Options(emitsXMLDeclaration: false,
                                             stripsComments: true)

        let node = Test2Node(element: .root,
                             attributes: [:],
                             children: [Test2Node(comment: "a -- b"),
                                        Test2Node(text: "x")])

        #expect(try formatted(node, options) == "<root>x</root>")
    }

    //  An element whose every child is stripped has no children left, and so
    //  must be written as an empty element rather than as an empty pair of tags.
    @Test
    func format_strippedOnlyChildYieldsEmptyElement() throws {
        let options = Test2Formatter.Options(emitsXMLDeclaration: false,
                                             stripsComments: true)

        let node = Test2Node(element: .root,
                             attributes: [:],
                             children: [Test2Node(comment: " note ")])

        #expect(try formatted(node, options) == "<root/>")
    }

    @Test
    func format_stripsComments() throws {
        let source = "<root>a<!-- note --><?pi d?>b</root>"
        let options = Test2Formatter.Options(emitsXMLDeclaration: false,
                                             stripsComments: true)

        #expect(try roundTrippedDocument(source, options) == "<root>a<?pi d?>b</root>")
    }

    @Test
    func format_stripsProcessingInstructions() throws {
        let source = "<root>a<!-- note --><?pi d?>b</root>"
        let options = Test2Formatter.Options(emitsXMLDeclaration: false,
                                             stripsProcessingInstructions: true)

        #expect(try roundTrippedDocument(source, options) == "<root>a<!-- note -->b</root>")
    }

    @Test
    func format_stripsPrologAndEpilog() throws {
        let source = "<!-- before --><?pi?><root>x</root><!-- after -->"
        let options = Test2Formatter.Options(emitsXMLDeclaration: false,
                                             stripsComments: true,
                                             stripsProcessingInstructions: true)

        #expect(try roundTrippedDocument(source, options) == "<root>x</root>")
    }

    @Test
    func format_textOnlyRoot() throws {
        let node = TestNode(element: .root,
                            attributes: [:],
                            children: [TestNode(text: "hello")])

        #expect(try formatted(node) == "<root>hello</root>")
    }

    @Test
    func format_treatsEmptyNamespaceAsNone() throws {
        let node = Test2Node(element: Test2Element("root", ""),
                             attributes: [:],
                             children: [])

        #expect(try formatted(node) == "<root/>")
    }

    @Test
    func format_unrecognizedSpaceValueIndentsNormally() throws {
        let node = element("root",
                           "bogus",
                           [element("child", nil, [])])

        #expect(try formattedIndented(node) == "<root xml:space=\"bogus\">\n  <child/>\n</root>\n")
    }

    @Test
    func format_xmlDeclarationOnOwnLine() throws {
        let node = TestNode(element: .root,
                            attributes: [:],
                            children: [])

        #expect(try formatted(node, .pretty) == "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>\n<root/>\n")
    }

    //  The XML namespace is bound to `xml` permanently and implicitly, so
    //  `xml:lang` is written without any declaration at all.
    @Test
    func format_xmlPrefixIsImplicit() throws {
        let node = Test3Node(element: Test2Element("root", nil),
                             attributes: [Test3Attribute("lang", "http://www.w3.org/XML/1998/namespace"): "en"],
                             children: [])

        #expect(try formatted(node) == "<root xml:lang=\"en\"/>")
    }

    //  A document using more than one namespace does not round-trip byte for
    //  byte: the prefixes are chosen by the formatter, not recovered from the
    //  source. What it does round-trip is meaning — every name resolves to the
    //  namespace it resolved to before.
    @Test
    func roundTrip_namespacedDocument() throws {
        let source = "<root xmlns=\"urn:one\"><child xmlns=\"urn:two\" id=\"1\">text</child></root>"

        #expect(try roundTripped(source) == "<ns1:root xmlns:ns1=\"urn:one\" xmlns:ns2=\"urn:two\">"
                                            + "<ns2:child id=\"1\">text</ns2:child></ns1:root>")
    }

    //  Formatting is idempotent even where it is not byte-preserving: the
    //  output of a round trip round-trips to itself.
    @Test
    func roundTrip_namespacedDocumentIsStable() throws {
        let source = "<root xmlns=\"urn:one\"><child xmlns=\"urn:two\" id=\"1\">text</child></root>"
        let once = try roundTripped(source)

        #expect(try roundTripped(once) == once)
    }

    @Test
    func roundTrip_nestedDocument() throws {
        let source = "<root id=\"1\"><item>one</item><item><child>two</child></item></root>"

        #expect(try roundTripped(source) == source)
    }

    @Test
    func roundTrip_preservedText() throws {
        let source = "<root xml:space=\"preserve\">the </root>"
        let node = try parsedNode(source)

        #expect(try formatted(node) == source)
    }

    @Test
    func roundTrip_preservedWhitespaceOnlyRuns() throws {
        let source = "<root xml:space=\"preserve\">\n  <child/>\n</root>"
        let node = try parsedNode(source)

        #expect(try formatted(node) == source)
    }

    @Test
    func roundTrip_specialCharacters() throws {
        let source = "<root name=\"a&lt;b&amp;c\">x &amp; y &lt; z</root>"

        #expect(try roundTripped(source) == source)
    }

    //  Line breaks are a function of indentation, so a compactly formatted
    //  document runs the prolog, the root element, and the epilog together —
    //  the whitespace around them is not recoverable and is not represented.
    @Test
    func roundTripDocument_comments() throws {
        let source = "<root>a<!-- note -->b</root>"

        #expect(try roundTrippedDocument(source, .init(emitsXMLDeclaration: false)) == source)
    }

    //  With indentation enabled, everything outside the root element gets its
    //  own line.
    @Test
    func roundTripDocument_indentedPrologAndEpilog() throws {
        let source = "<?xml version=\"1.0\"?><!-- license --><root><child>x</child></root><!-- trailer -->"

        let expected = """
                       <?xml version="1.0" encoding="UTF-8" standalone="no"?>
                       <!-- license -->
                       <root>
                           <child>x</child>
                       </root>
                       <!-- trailer -->

                       """

        let options = Test2Formatter.Options(emitsXMLDeclaration: true,
                                             indentation: 4)

        #expect(try roundTrippedDocument(source, options) == expected)
    }

    //  The case this whole capability exists for: a document identified by its
    //  DOCTYPE must still identify itself after a round trip.
    @Test
    func roundTripDocument_musicXMLHeader() throws {
        let source = """
                     <?xml version="1.0" encoding="UTF-8" standalone="no"?>
                     <!DOCTYPE root PUBLIC "-//Recordare//DTD MusicXML 4.0 Partwise//EN"
                         "http://www.musicxml.org/dtds/partwise.dtd">
                     <root id="4.0"><child>x</child></root>
                     """

        let expected = """
                       <?xml version="1.0" encoding="UTF-8" standalone="no"?>\
                       <!DOCTYPE root PUBLIC "-//Recordare//DTD MusicXML 4.0 Partwise//EN"\
                        "http://www.musicxml.org/dtds/partwise.dtd">\
                       <root id="4.0"><child>x</child></root>
                       """

        #expect(try roundTrippedDocument(source) == expected)
    }

    @Test
    func roundTripDocument_prologAndEpilog() throws {
        let source = """
                     <?xml version="1.0"?>
                     <?xml-stylesheet href="a.xsl"?>
                     <!-- license -->
                     <root>x</root>
                     <!-- trailer -->
                     """

        let expected = """
                       <?xml version="1.0" encoding="UTF-8" standalone="no"?>\
                       <?xml-stylesheet href="a.xsl"?>\
                       <!-- license -->\
                       <root>x</root>\
                       <!-- trailer -->
                       """

        #expect(try roundTrippedDocument(source) == expected)
    }
}
