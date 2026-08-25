// © 2026 John Gary Pusey (see LICENSE.md)

import Testing
@testable import XestiXML

struct XMLFormatterNamespaceTableTests {
}

// MARK: -

extension XMLFormatterNamespaceTableTests {
    @Test
    func attributeName_neverUsesDefaultNamespace() throws {
        let root = Test3Node(element: Test2Element("root", "urn:a"),
                             attributes: [Test3Attribute("id", "urn:a"): "1"],
                             children: [])
        let table = try Test3Formatter.NamespaceTable(Test3Formatter.Options(), root)

        #expect(table.elementName("root", "urn:a") == "root")
        #expect(table.attributeName("id", "urn:a") == "ns1:id")
    }

    @Test
    func attributeName_noURIReturnsPlainName() {
        let table = Test2Formatter.NamespaceTable()

        #expect(table.attributeName("id", nil) == "id")
    }

    @Test
    func attributeName_xmlNamespaceUsesHardcodedPrefix() throws {
        let xmlURI = "http://www.w3.org/XML/1998/namespace"
        let root = Test3Node(element: Test2Element("root", nil),
                             attributes: [Test3Attribute("lang", xmlURI): "en"],
                             children: [])
        let table = try Test3Formatter.NamespaceTable(Test3Formatter.Options(), root)

        #expect(table.declarations.isEmpty)
        #expect(table.attributeName("lang", xmlURI) == "xml:lang")
    }

    @Test
    func elementName_noURIReturnsPlainName() {
        let table = Test2Formatter.NamespaceTable()

        #expect(table.elementName("root", nil) == "root")
    }

    @Test
    func init_duplicateDefaultNamespaceThrows() {
        let namespaces = [Test2Formatter.Namespace(prefix: nil, uri: "urn:a"),
                          Test2Formatter.Namespace(prefix: nil, uri: "urn:b")]
        let root = Test2Node(element: Test2Element("root", nil), attributes: [:], children: [])
        let options = Test2Formatter.Options(namespaces: namespaces)

        #expect(throws: Test2Formatter.Error.self) {
            try Test2Formatter.NamespaceTable(options, root)
        }
    }

    @Test
    func init_duplicatePrefixThrows() {
        let namespaces = [Test2Formatter.Namespace(prefix: "a", uri: "urn:a"),
                          Test2Formatter.Namespace(prefix: "a", uri: "urn:b")]
        let root = Test2Node(element: Test2Element("root", nil), attributes: [:], children: [])
        let options = Test2Formatter.Options(namespaces: namespaces)

        #expect(throws: Test2Formatter.Error.self) {
            try Test2Formatter.NamespaceTable(options, root)
        }
    }

    @Test
    func init_duplicateURIThrows() {
        let namespaces = [Test2Formatter.Namespace(prefix: "a", uri: "urn:a"),
                          Test2Formatter.Namespace(prefix: "b", uri: "urn:a")]
        let root = Test2Node(element: Test2Element("root", nil), attributes: [:], children: [])
        let options = Test2Formatter.Options(namespaces: namespaces)

        #expect(throws: Test2Formatter.Error.self) {
            try Test2Formatter.NamespaceTable(options, root)
        }
    }

    @Test
    func init_emptyURIThrows() {
        let namespaces = [Test2Formatter.Namespace(prefix: "a", uri: "")]
        let root = Test2Node(element: Test2Element("root", nil), attributes: [:], children: [])
        let options = Test2Formatter.Options(namespaces: namespaces)

        #expect(throws: Test2Formatter.Error.self) {
            try Test2Formatter.NamespaceTable(options, root)
        }
    }

    @Test
    func init_explicitDefaultNamespaceOptionSurvivesUnnamespacedSibling() throws {
        let child = Test2Node(element: Test2Element("child", nil), attributes: [:], children: [])
        let root = Test2Node(element: Test2Element("root", "urn:a"), attributes: [:], children: [child])
        let namespaces = [Test2Formatter.Namespace(prefix: nil, uri: "urn:a")]
        let options = Test2Formatter.Options(namespaces: namespaces)
        let table = try Test2Formatter.NamespaceTable(options, root)

        #expect(table.declarations.count == 1)
        #expect(table.elementName("root", "urn:a") == "root")
        #expect(table.elementName("child", nil) == "child")
    }

    @Test
    func init_explicitPrefixOptionIsUsed() throws {
        let root = Test2Node(element: Test2Element("root", "urn:a"), attributes: [:], children: [])
        let namespaces = [Test2Formatter.Namespace(prefix: "a", uri: "urn:a")]
        let options = Test2Formatter.Options(namespaces: namespaces)
        let table = try Test2Formatter.NamespaceTable(options, root)

        #expect(table.elementName("root", "urn:a") == "a:root")
    }

    @Test
    func init_multipleNamespacesNumberedInDocumentOrder() throws {
        let child = Test2Node(element: Test2Element("child", "urn:b"), attributes: [:], children: [])
        let root = Test2Node(element: Test2Element("root", "urn:a"), attributes: [:], children: [child])
        let table = try Test2Formatter.NamespaceTable(Test2Formatter.Options(), root)

        #expect(table.declarations.map(\.0) == ["ns1", "ns2"])
        #expect(table.elementName("root", "urn:a") == "ns1:root")
        #expect(table.elementName("child", "urn:b") == "ns2:child")
    }

    @Test
    func init_noArgHasNoDeclarations() {
        let table = Test2Formatter.NamespaceTable()

        #expect(table.declarations.isEmpty)
    }

    @Test
    func init_reservedXMLNamespaceURIThrows() {
        let xmlURI = "http://www.w3.org/XML/1998/namespace"
        let namespaces = [Test2Formatter.Namespace(prefix: "a", uri: xmlURI)]
        let root = Test2Node(element: Test2Element("root", nil), attributes: [:], children: [])
        let options = Test2Formatter.Options(namespaces: namespaces)

        #expect(throws: Test2Formatter.Error.self) {
            try Test2Formatter.NamespaceTable(options, root)
        }
    }

    @Test
    func init_reservedXMLPrefixThrows() {
        let namespaces = [Test2Formatter.Namespace(prefix: "xml", uri: "urn:a")]
        let root = Test2Node(element: Test2Element("root", nil), attributes: [:], children: [])
        let options = Test2Formatter.Options(namespaces: namespaces)

        #expect(throws: Test2Formatter.Error.self) {
            try Test2Formatter.NamespaceTable(options, root)
        }
    }

    @Test
    func init_singleNamespaceBecomesDefault() throws {
        let child = Test2Node(element: Test2Element("child", "urn:a"), attributes: [:], children: [])
        let root = Test2Node(element: Test2Element("root", "urn:a"), attributes: [:], children: [child])
        let table = try Test2Formatter.NamespaceTable(Test2Formatter.Options(), root)

        #expect(table.declarations.count == 1)
        #expect(table.declarations.first?.0 == nil)
        #expect(table.declarations.first?.1 == "urn:a")
        #expect(table.elementName("root", "urn:a") == "root")
    }

    @Test
    func init_unnamespacedSiblingBlocksAutomaticDefault() throws {
        let child = Test2Node(element: Test2Element("child", "urn:a"), attributes: [:], children: [])
        let root = Test2Node(element: Test2Element("root", nil), attributes: [:], children: [child])
        let table = try Test2Formatter.NamespaceTable(Test2Formatter.Options(), root)

        #expect(table.elementName("root", nil) == "root")
        #expect(table.elementName("child", "urn:a") == "ns1:child")
    }
}
