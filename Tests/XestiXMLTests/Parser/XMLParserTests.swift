// © 2026 John Gary Pusey (see LICENSE.md)

//  Every test of `XMLParser` lives here, so that one source file maps to one
//  test file; the length that follows from it is not worth splitting the type's
//  tests across several files for.
// swiftlint:disable file_length

import Foundation
import Testing
import XestiTools
@testable import XestiXML

struct XMLParserTests {
}

// MARK: -

extension XMLParserTests {
    @Test
    func parse_abortReportsPosition() {
        let data = Data("<root>\n<child/>\n<unknown/>\n</root>".utf8)
        var capturedError: Test2Parser.Error?

        do {
            _ = try Test2Parser().parse(data).root
        } catch {
            capturedError = error
        }

        if case let .unrecognizedElement(name, _, line, _) = capturedError {
            #expect(name == "unknown")
            #expect(line == 3)
        } else {
            Issue.record("Expected unrecognizedElement error")
        }
    }

    //  libxml2 reports advisory diagnostics through the same channel as genuine
    //  defects. An XML 1.1 declaration is a convenient trigger: libxml2 does not
    //  support version 1.1, warns, and then parses the document as 1.0.
    @Test
    func parse_advisoryDiagnosticDoesNotFailParse() throws {
        let data = Data("<?xml version=\"1.1\"?><root>hello</root>".utf8)
        let node = try Test2Parser().parse(data).root

        #expect(node.value == "hello")
    }

    @Test
    func parse_advisoryDiagnosticDoesNotMaskLaterFailure() {
        let data = Data("<?xml version=\"1.1\"?><root>hello</bad>".utf8)
        var capturedError: Test2Parser.Error?

        do {
            _ = try Test2Parser().parse(data).root
        } catch {
            capturedError = error
        }

        if case let .parseFailure(cause, _, _) = capturedError {
            #expect(cause?.message.contains("mismatch") == true)
        } else {
            Issue.record("Expected parseFailure error")
        }
    }

    @Test
    func parse_advisoryDiagnosticDoesNotMaskTrailingContent() {
        let data = Data("<?xml version=\"1.1\"?><root>hello</root><extra/>".utf8)
        var capturedError: Test2Parser.Error?

        do {
            _ = try Test2Parser().parse(data).root
        } catch {
            capturedError = error
        }

        if case let .parseFailure(cause, _, _) = capturedError {
            #expect(cause?.message.contains("Extra content") == true)
        } else {
            Issue.record("Expected parseFailure error")
        }
    }

    @Test
    func parse_ampersandInAttributeValue() throws {
        let data = Data("<root name=\"a&amp;b\"/>".utf8)
        let node = try Test2Parser().parse(data).root

        #expect(node.attributes?[.name] == "a&b")
    }

    @Test
    func parse_attributeNamespaceURI() throws {
        let data = Data("<root xmlns:a=\"urn:a\" a:id=\"1\"/>".utf8)
        let node = try Test3Parser().parse(data).root

        #expect(node.attributes?[Test3Attribute("id", "urn:a")] == "1")
    }

    @Test
    func parse_cdataAdjacentToText() throws {
        let data = Data("<root>a<![CDATA[<b>]]>c</root>".utf8)
        let node = try Test2Parser().parse(data).root

        #expect(node.children?.count == 1)
        #expect(node.value == "a<b>c")
    }

    @Test
    func parse_cdataContent() throws {
        let data = Data("<root><![CDATA[hello <world>]]></root>".utf8)
        let node = try Test2Parser().parse(data).root

        #expect(node.value == "hello <world>")
    }

    @Test
    func parse_cdataInsidePreserve() throws {
        let node = try parsedNode("<root xml:space=\"preserve\"><![CDATA[a  b]]></root>")

        #expect(node.value == "a  b")
    }

    @Test
    func parse_commentRetainedByDefault() throws {
        let data = Data("<root>a<!-- note -->b</root>".utf8)
        let node = try Test2Parser().parse(data).root

        #expect(node.children?.count == 3)
        #expect(node.children?[1].isComment == true)
        #expect(node.children?[1].comment == " note ")
    }

    //  Comments and processing instructions are not character data, so they
    //  must not disturb the value of the element containing them.
    @Test
    func parse_commentRetainedDoesNotAffectValue() throws {
        let data = Data("<root>a<!-- note --><?pi d?>b</root>".utf8)
        let node = try Test2Parser().parse(data).root

        #expect(node.value == "ab")
    }

    @Test
    func parse_commentStripped() throws {
        let data = Data("<root>a<!-- note -->b</root>".utf8)
        let options = Test2Parser.Options(stripsComments: true)
        let node = try Test2Parser(options: options).parse(data).root

        #expect(node.children?.count == 1)
        #expect(node.value == "ab")
    }

    @Test
    func parse_commentWithinInternalSubsetAlwaysIgnored() throws {
        let source = """
                     <!DOCTYPE root [<!-- inside --><?inside-pi d?><!ELEMENT root EMPTY>]>\
                     <!-- outside -->\
                     <root/>
                     """

        let document = try parsedDocument(source)

        #expect(document.prolog.count == 1)
        #expect(document.prolog.first?.comment == " outside ")
    }

    @Test
    func parse_deeplyNested() throws {
        let depth = 500
        let source = "<root>"
            + String(repeating: "<child>", count: depth)
            + String(repeating: "</child>", count: depth)
            + "</root>"

        let node = try Test2Parser().parse(Data(source.utf8)).root

        var current = node
        var seen = 0

        while let child = current.children?.first {
            current = child
            seen += 1
        }

        #expect(seen == depth)
    }

    @Test
    func parse_defaultNamespaceOnElement() throws {
        let data = Data("<root xmlns=\"urn:d\"/>".utf8)
        let node = try Test2Parser().parse(data).root

        #expect(node.uri == "urn:d")
    }

    @Test
    func parse_defaultOverridesPreserveOnDescendant() throws {
        let node = try parsedNode("<root xml:space=\"preserve\">"
                                  + "<child xml:space=\"default\">  a   b  </child>"
                                  + "</root>")
        let child = try #require(node.children?.first { $0.isElement })

        #expect(child.value == "a b")
    }

    @Test
    func parse_documentTypeBare() throws {
        let document = try parsedDocument("<!DOCTYPE root><root/>")

        #expect(document.documentType?.name == "root")
        #expect(document.documentType?.publicID == nil)
        #expect(document.documentType?.systemID == nil)
    }

    @Test
    func parse_documentTypePublic() throws {
        let source = """
                     <!DOCTYPE root PUBLIC "-//Recordare//DTD MusicXML 4.0 Partwise//EN"\
                      "http://www.musicxml.org/dtds/partwise.dtd">\
                     <root/>
                     """

        let document = try parsedDocument(source)

        #expect(document.documentType?.name == "root")
        #expect(document.documentType?.publicID == "-//Recordare//DTD MusicXML 4.0 Partwise//EN")
        #expect(document.documentType?.systemID == "http://www.musicxml.org/dtds/partwise.dtd")
    }

    @Test
    func parse_documentTypeSystem() throws {
        let document = try parsedDocument("<!DOCTYPE root SYSTEM \"root.dtd\"><root/>")

        #expect(document.documentType?.publicID == nil)
        #expect(document.documentType?.systemID == "root.dtd")
    }

    @Test
    func parse_elementsWithTextAndChildren() throws {
        let data = Data("<root>text<child/>more</root>".utf8)
        let node = try Test2Parser().parse(data).root

        #expect(node.children?.count == 3)
    }

    @Test
    func parse_elementWithAttributes() throws {
        let data = Data("<root id=\"1\" name=\"test\"/>".utf8)
        let node = try Test2Parser().parse(data).root

        #expect(node.element == .root)
        #expect(node.attributes?[.id] == "1")
        #expect(node.attributes?[.name] == "test")
    }

    @Test
    func parse_emptyData() {
        #expect(throws: Test2Parser.Error.self) {
            try Test2Parser().parse(Data()).root
        }
    }

    @Test
    func parse_externalEntityThrows() {
        let data = Data("""
                        <!DOCTYPE root [<!ENTITY ee SYSTEM "file:///etc/passwd">]>\
                        <root>A[&ee;]B</root>
                        """.utf8)

        #expect(throws: Test2Parser.Error.self) {
            try Test2Parser().parse(data).root
        }
    }

    @Test
    func parse_internalEntityExpanded() throws {
        let data = Data("<!DOCTYPE root [<!ENTITY e \"X\">]><root>A&e;B</root>".utf8)
        let node = try Test2Parser().parse(data).root

        #expect(node.value == "AXB")
    }

    @Test
    func parse_invalidXML() {
        let data = Data("not xml at all".utf8)

        #expect(throws: Test2Parser.Error.self) {
            try Test2Parser().parse(data).root
        }
    }

    @Test
    func parse_latin1Declared() throws {
        var data = Data("<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?><root>caf".utf8)

        data.append(0xe9)   // `é` in ISO-8859-1
        data.append(contentsOf: Array("</root>".utf8))

        let node = try Test2Parser().parse(data).root

        #expect(node.value == "café")
    }

    @Test
    func parse_malformedXML() {
        let data = Data("<root><".utf8)

        #expect(throws: Test2Parser.Error.self) {
            try Test2Parser().parse(data).root
        }
    }

    @Test
    func parse_mixedContent() throws {
        let data = Data("<root><child>text1</child><item>text2</item></root>".utf8)
        let node = try Test2Parser().parse(data).root

        #expect(node.children?.count == 2)
        #expect(node.firstChildElement(.child)?.value == "text1")
        #expect(node.firstChildElement(.item)?.value == "text2")
    }

    @Test
    func parse_multipleSiblings() throws {
        let data = Data("<root><child/><child/><child/></root>".utf8)
        let node = try Test2Parser().parse(data).root

        #expect(node.allChildElements(.child).count == 3)
    }

    @Test
    func parse_namespacedAttributes() throws {
        let data = Data("<root xmlns:a=\"urn:a\" a:id=\"1\" id=\"2\"/>".utf8)
        let node = try Test3Parser().parse(data).root

        //  The prefix is discarded; the namespace URI is what identifies the
        //  attribute. `a:id` and a plain `id` are therefore distinct keys,
        //  where joining the prefix into the name once made them collide.
        #expect(node.attributes?.count == 2)
        #expect(node.attributes?[Test3Attribute("id", "urn:a")] == "1")
        #expect(node.attributes?[Test3Attribute("id", nil)] == "2")
    }

    //  A namespace declaration is not an attribute. libxml2 never reports one
    //  among them, and neither does the tree.
    @Test
    func parse_namespaceDeclarationsAreNotAttributes() throws {
        let data = Data("<root xmlns=\"urn:d\" xmlns:a=\"urn:a\"/>".utf8)
        let node = try Test3Parser().parse(data).root

        #expect(node.attributes?.isEmpty == true)
    }

    @Test
    func parse_nestedElements() throws {
        let data = Data("<root><child><item/></child></root>".utf8)
        let node = try Test2Parser().parse(data).root

        #expect(node.element == .root)
        #expect(node.children?.count == 1)
        #expect(node.children?.first?.element == .child)
        #expect(node.children?.first?.children?.first?.element == .item)
    }

    @Test
    func parse_nestedElements_rawRepresentable() throws {
        let data = Data("<root><child/></root>".utf8)
        let node = try TestParser().parse(data).root

        #expect(node.element == .root)
        #expect(node.children?.first?.element == .child)
    }

    @Test
    func parse_noDocumentType() throws {
        let document = try parsedDocument("<root/>")

        #expect(document.documentType == nil)
    }

    @Test
    func parse_noNamespaceReportsNilURI() throws {
        let data = Data("<root/>".utf8)
        let node = try Test2Parser().parse(data).root

        #expect(node.uri == nil)
    }

    @Test
    func parse_normalizesByDefault() throws {
        let node = try parsedNode("<root>  a   b  </root>")

        #expect(node.value == "a b")
    }

    @Test
    func parse_noXMLDeclaration() throws {
        let document = try parsedDocument("<root/>")

        #expect(document.declaration == nil)
    }

    @Test
    func parse_numericCharacterReference() throws {
        let data = Data("<root>&#65;</root>".utf8)
        let node = try Test2Parser().parse(data).root

        #expect(node.value == "A")
    }

    @Test
    func parse_numericCharacterReferenceInAttributeValue() throws {
        let data = Data("<root name=\"a&#38;b\"/>".utf8)
        let node = try Test2Parser().parse(data).root

        #expect(node.attributes?[.name] == "a&b")
    }

    @Test
    func parse_predefinedEntity() throws {
        let data = Data("<root>a &amp; b</root>".utf8)
        let node = try Test2Parser().parse(data).root

        #expect(node.value == "a & b")
    }

    @Test
    func parse_preserveDoesNotLeakToSibling() throws {
        let node = try parsedNode("<root>"
                                  + "<child xml:space=\"preserve\">a  b</child>"
                                  + "<item>c  d</item>"
                                  + "</root>")
        let children = try #require(node.children)

        #expect(children[0].value == "a  b")
        #expect(children[1].value == "c d")
    }

    @Test
    func parse_preserveIsInherited() throws {
        let node = try parsedNode("<root xml:space=\"preserve\"><child>a  b</child></root>")
        let child = try #require(node.children?.first)

        #expect(child.value == "a  b")
    }

    //  Restoring, not merely clearing: the text after the child is the root's
    //  again, and the root still asked for preservation.
    @Test
    func parse_preserveRestoredAfterChild() throws {
        let node = try parsedNode("<root xml:space=\"preserve\">  "
                                  + "<child xml:space=\"default\">x</child>"
                                  + "  </root>")
        let children = try #require(node.children)

        #expect(children.count == 3)
        #expect(children[0].value == "  ")
        #expect(children[2].value == "  ")
    }

    //  The MusicXML case: a trailing space is how a lyric syllable joins the
    //  one after it, so losing it changes what is rendered.
    @Test
    func parse_preservesSignificantTrailingSpace() throws {
        let node = try parsedNode("<root xml:space=\"preserve\">the </root>")

        #expect(node.value == "the ")
    }

    @Test
    func parse_preservesSpaceWhenAsked() throws {
        let node = try parsedNode("<root xml:space=\"preserve\">  a   b  </root>")

        #expect(node.value == "  a   b  ")
    }

    @Test
    func parse_processingInstructionRetained() throws {
        let data = Data("<root><?xml-stylesheet href=\"a.xsl\"?></root>".utf8)
        let node = try Test2Parser().parse(data).root

        #expect(node.children?.count == 1)
        #expect(node.children?.first?.isProcessingInstruction == true)
        #expect(node.children?.first?.target == "xml-stylesheet")
        #expect(node.children?.first?.data == "href=\"a.xsl\"")
    }

    @Test
    func parse_processingInstructionRetainedWithoutData() throws {
        let data = Data("<root><?bare?></root>".utf8)
        let node = try Test2Parser().parse(data).root

        #expect(node.children?.first?.target == "bare")
        #expect(node.children?.first?.data == nil)
    }

    @Test
    func parse_prologAndEpilog() throws {
        let source = """
                     <!-- before -->\
                     <?pi-before?>\
                     <root>inside</root>\
                     <!-- after -->
                     """

        let document = try parsedDocument(source)

        #expect(document.prolog.count == 2)
        #expect(document.prolog.first?.comment == " before ")
        #expect(document.prolog.last?.target == "pi-before")
        #expect(document.root.value == "inside")
        #expect(document.epilog.count == 1)
        #expect(document.epilog.first?.comment == " after ")
    }

    @Test
    func parse_prologAndEpilogEmptyWhenStripped() throws {
        let options = Test2Parser.Options(stripsComments: true,
                                          stripsProcessingInstructions: true)

        let document = try parsedDocument("<!-- before --><root/><!-- after -->", options)

        #expect(document.prolog.isEmpty)
        #expect(document.epilog.isEmpty)
    }

    //  The same prefix bound to different URIs on nested elements yields
    //  distinct attributes, which the discarded-prefix model gets right and a
    //  qualified-name model cannot.
    @Test
    func parse_rebindsPrefixOnDescendant() throws {
        let source = "<root xmlns:a=\"urn:one\" a:id=\"1\">"
                     + "<child xmlns:a=\"urn:two\" a:id=\"2\"/>"
                     + "</root>"
        let node = try Test3Parser().parse(Data(source.utf8)).root
        let child = try #require(node.children?.first)

        #expect(node.attributes?[Test3Attribute("id", "urn:one")] == "1")
        #expect(child.attributes?[Test3Attribute("id", "urn:two")] == "2")
    }

    @Test
    func parse_recursiveEntityThrows() {
        let data = Data("""
                        <!DOCTYPE root [<!ENTITY a "&b;"><!ENTITY b "&a;">]>\
                        <root>&a;</root>
                        """.utf8)

        #expect(throws: Test2Parser.Error.self) {
            try Test2Parser().parse(data).root
        }
    }

    @Test
    func parse_repeatedParsesAreIndependent() throws {
        let parser = Test2Parser()

        let first = try parser.parse(Data("<root>one</root>".utf8)).root
        let second = try parser.parse(Data("<root><child>two</child></root>".utf8)).root
        let third = try parser.parse(Data("<root>one</root>".utf8)).root

        #expect(first.value == "one")
        #expect(second.firstChildElement(.child)?.value == "two")
        #expect(third.value == "one")
    }

    @Test
    func parse_simpleElement() throws {
        let data = Data("<root/>".utf8)
        let node = try Test2Parser().parse(data).root

        #expect(node.element == .root)
        #expect(node.children?.isEmpty == true)
        #expect(node.attributes?.isEmpty == true)
    }

    @Test
    func parse_simpleElement_rawRepresentable() throws {
        let data = Data("<root/>".utf8)
        let node = try TestParser().parse(data).root

        #expect(node.element == .root)
    }

    @Test
    func parse_stripsCommentsIndependentlyOfProcessingInstructions() throws {
        let source = "<root><!-- note --><?pi d?></root>"
        let options = Test2Parser.Options(stripsProcessingInstructions: true)
        let node = try Test2Parser(options: options).parse(Data(source.utf8)).root

        #expect(node.children?.count == 1)
        #expect(node.children?.first?.isComment == true)
    }

    @Test
    func parse_textContent() throws {
        let data = Data("<root>hello world</root>".utf8)
        let node = try Test2Parser().parse(data).root

        #expect(node.value == "hello world")
    }

    @Test
    func parse_undeclaredAttributePrefixThrows() {
        #expect(throws: Test3Parser.Error.self) {
            try Test3Parser().parse(Data("<root a:id=\"1\"/>".utf8))
        }
    }

    //  An undeclared prefix has to be rejected rather than tolerated: it
    //  resolves to nothing, so `startElementNs` reports the name with a NULL
    //  URI, which is indistinguishable from a name in no namespace at all. A
    //  tolerated one would parse as an ordinary unqualified name.
    @Test
    func parse_undeclaredElementPrefixThrows() {
        #expect(throws: Test3Parser.Error.self) {
            try Test3Parser().parse(Data("<root><a:child/></root>".utf8))
        }
    }

    @Test
    func parse_undeclaredEntityThrows() {
        let data = Data("<root>&nope;</root>".utf8)

        #expect(throws: Test2Parser.Error.self) {
            try Test2Parser().parse(data).root
        }
    }

    @Test
    func parse_undefinedNamespacePrefixOnAttributeThrows() {
        let data = Data("<root><child q:id=\"1\"/></root>".utf8)

        #expect(throws: Test3Parser.Error.self) {
            try Test3Parser().parse(data).root
        }
    }

    //  libxml2 reports an unbound prefix without clearing `wellFormed`, so the
    //  parse runs to completion; the element would otherwise be delivered as
    //  though it were in no namespace at all.
    @Test
    func parse_undefinedNamespacePrefixThrows() {
        let data = Data("<root><q:child/></root>".utf8)

        #expect(throws: Test2Parser.Error.self) {
            try Test2Parser().parse(data).root
        }
    }

    //  The default namespace applies to element names only. An unprefixed
    //  attribute is in no namespace at all, however emphatically the enclosing
    //  element declares a default.
    @Test
    func parse_unprefixedAttributeHasNoNamespace() throws {
        let data = Data("<root xmlns=\"urn:d\" id=\"1\"/>".utf8)
        let node = try Test3Parser().parse(data).root

        #expect(node.uri == "urn:d")
        #expect(node.attributes?[Test3Attribute("id", nil)] == "1")
    }

    @Test
    func parse_unrecognizedAttribute() {
        let data = Data("<root unknown=\"value\"/>".utf8)

        #expect(throws: Test2Parser.Error.self) {
            try Test2Parser().parse(data).root
        }
    }

    @Test
    func parse_unrecognizedElement() {
        let data = Data("<root><unknown/></root>".utf8)

        #expect(throws: Test2Parser.Error.self) {
            try Test2Parser().parse(data).root
        }
    }

    @Test
    func parse_unrecognizedRootElement() {
        let data = Data("<unknown/>".utf8)

        #expect(throws: Test2Parser.Error.self) {
            try Test2Parser().parse(data).root
        }
    }

    @Test
    func parse_unrecognizedRootElement_reportsNilURIForNoNamespace() {
        let data = Data("<unknown/>".utf8)
        var capturedError: TestParser.Error?

        do {
            _ = try TestParser().parse(data).root
        } catch {
            capturedError = error
        }

        if case let .unrecognizedElement(_, uri, _, _) = capturedError {
            #expect(uri == nil)
        } else {
            Issue.record("Expected unrecognizedElement error")
        }
    }

    //  XML 1.0 defines only `default` and `preserve`; libxml2 reports anything
    //  else as a warning, which is discarded, so the attribute is ignored.
    @Test
    func parse_unrecognizedSpaceValueIgnored() throws {
        let node = try parsedNode("<root xml:space=\"bogus\">  a   b  </root>")

        #expect(node.value == "a b")
    }

    @Test
    func parse_utf16Declared() throws {
        let source = "<?xml version=\"1.0\" encoding=\"UTF-16\"?><root>hello</root>"
        let data = try #require(source.data(using: .utf16LittleEndian))
        let node = try Test2Parser().parse(Data([0xff, 0xfe]) + data).root

        #expect(node.value == "hello")
    }

    @Test
    func parse_utf16WithBOM() throws {
        let source = "<root>hello</root>"
        let data = try #require(source.data(using: .utf16LittleEndian))
        let node = try Test2Parser().parse(Data([0xff, 0xfe]) + data).root

        #expect(node.value == "hello")
    }

    @Test
    func parse_utf8MultibyteTextSplitAcrossChunks() throws {
        let data = Data("<root>héllo wörld — ünïcodé</root>".utf8)
        let node = try Test2Parser().parse(data).root

        #expect(node.children?.count == 1)
        #expect(node.value == "héllo wörld — ünïcodé")
    }

    //  Under preservation a run of nothing but whitespace is content, so it
    //  becomes a text node instead of vanishing. This is the change that shifts
    //  child counts for anyone parsing such a document.
    @Test
    func parse_whitespaceOnlyRunBecomesTextNode() throws {
        let node = try parsedNode("<root xml:space=\"preserve\">\n  <child/>\n</root>")
        let children = try #require(node.children)

        #expect(children.count == 3)
        #expect(children[0].value == "\n  ")
        #expect(children[1].isElement)
        #expect(children[2].value == "\n")
    }

    @Test
    func parse_whitespaceOnlyRunDroppedByDefault() throws {
        let node = try parsedNode("<root>\n  <child/>\n</root>")

        #expect(node.children?.count == 1)
    }

    @Test
    func parse_whitespaceTextNormalized() throws {
        let data = Data("<root>  hello  world  </root>".utf8)
        let node = try Test2Parser().parse(data).root

        #expect(node.value == "hello world")
    }

    @Test
    func parse_xmlDeclarationFull() throws {
        let document = try parsedDocument("<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?><root/>")

        #expect(document.declaration?.version == "1.0")
        #expect(document.declaration?.encoding == "UTF-8")
        #expect(document.declaration?.isStandalone == true)
    }

    //  The XML declaration is not a processing instruction and must never be
    //  reported as one.
    @Test
    func parse_xmlDeclarationNotAProcessingInstruction() throws {
        let document = try parsedDocument("<?xml version=\"1.0\"?><root/>")

        #expect(document.prolog.isEmpty)
    }

    //  A declaration that says nothing about standalone must be distinguishable
    //  from one that says "no".
    @Test
    func parse_xmlDeclarationStandaloneAbsent() throws {
        let document = try parsedDocument("<?xml version=\"1.0\"?><root/>")

        #expect(document.declaration != nil)
        #expect(document.declaration?.encoding == nil)
        #expect(document.declaration?.isStandalone == nil)
    }

    @Test
    func parse_xmlDeclarationStandaloneNo() throws {
        let document = try parsedDocument("<?xml version=\"1.0\" standalone=\"no\"?><root/>")

        #expect(document.declaration?.isStandalone == false)
    }

    @Test
    func parse_xmlnsNotAnAttribute() throws {
        let data = Data("<root xmlns:a=\"urn:a\" xmlns=\"urn:d\"/>".utf8)
        let node = try Test3Parser().parse(data).root

        #expect(node.attributes?.isEmpty == true)
    }

    //  The `xml` prefix is bound without any declaration in the document.
    @Test
    func parse_xmlPrefixedAttribute() throws {
        let data = Data("<root xml:lang=\"en\"/>".utf8)
        let node = try Test3Parser().parse(data).root

        #expect(node.attributes?[Test3Attribute("lang", "http://www.w3.org/XML/1998/namespace")] == "en")
    }

    //  A prefixed attribute survives a round trip with its namespace intact,
    //  though not necessarily with the prefix the source used.
    @Test
    func roundTrip_prefixedAttribute() throws {
        let data = Data("<root xmlns:a=\"urn:a\" a:id=\"1\"/>".utf8)
        let node = try Test3Parser().parse(data).root

        #expect(try formatted(node) == "<root xmlns:ns1=\"urn:a\" ns1:id=\"1\"/>")
    }
}
