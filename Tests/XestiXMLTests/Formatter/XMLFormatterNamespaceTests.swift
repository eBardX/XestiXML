// © 2026 John Gary Pusey (see LICENSE.md)

import Testing
@testable import XestiXML

struct XMLFormatterNamespaceTests {
}

// MARK: -

extension XMLFormatterNamespaceTests {
    @Test
    func equality_differentPrefix() {
        #expect(TestFormatter.Namespace(prefix: "a", uri: "urn:a")
                != TestFormatter.Namespace(prefix: "b", uri: "urn:a"))
    }

    @Test
    func equality_differentURI() {
        #expect(TestFormatter.Namespace(prefix: "a", uri: "urn:a")
                != TestFormatter.Namespace(prefix: "a", uri: "urn:b"))
    }

    @Test
    func equality_sameValues() {
        let one = TestFormatter.Namespace(prefix: "a", uri: "urn:a")
        let other = TestFormatter.Namespace(prefix: "a", uri: "urn:a")

        #expect(one == other)
    }

    @Test
    func hashable() {
        var set = Set<TestFormatter.Namespace>()

        set.insert(TestFormatter.Namespace(prefix: "a", uri: "urn:a"))
        set.insert(TestFormatter.Namespace(prefix: "a", uri: "urn:a"))
        set.insert(TestFormatter.Namespace(prefix: "b", uri: "urn:a"))

        #expect(set.count == 2)
    }

    @Test
    func init_defaultNamespace() {
        let namespace = TestFormatter.Namespace(prefix: nil, uri: "urn:a")

        #expect(namespace.prefix == nil)
        #expect(namespace.uri == "urn:a")
    }

    @Test
    func init_explicitPrefix() {
        let namespace = TestFormatter.Namespace(prefix: "a", uri: "urn:a")

        #expect(namespace.prefix == "a")
        #expect(namespace.uri == "urn:a")
    }
}
