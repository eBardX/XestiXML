// © 2026 John Gary Pusey (see LICENSE.md)

import Testing
@testable import XestiXML

struct XMLNodeConvenienceTests {
}

// MARK: -

extension XMLNodeConvenienceTests {
    @Test
    func expectElement_matching() throws {
        let node = TestNode(element: .root,
                            attributes: [:],
                            children: [])

        try node.expectElement(.root)
    }

    @Test
    func expectElement_notMatching() {
        let node = TestNode(element: .root,
                            attributes: [:],
                            children: [])

        #expect(throws: TestNode.Error.self) {
            try node.expectElement(.child)
        }
    }

    @Test
    func hasChildElement_false() {
        let child = TestNode(element: .child,
                             attributes: [:],
                             children: [])
        let node = TestNode(element: .root,
                            attributes: [:],
                            children: [child])

        #expect(!node.hasChildElement(.item))
    }

    @Test
    func hasChildElement_true() {
        let child = TestNode(element: .child,
                             attributes: [:],
                             children: [])
        let node = TestNode(element: .root,
                            attributes: [:],
                            children: [child])

        #expect(node.hasChildElement(.child))
    }

    @Test
    func hasChildElement_withArray() {
        let child = TestNode(element: .child,
                             attributes: [:],
                             children: [])
        let node = TestNode(element: .root,
                            attributes: [:],
                            children: [child])

        #expect(node.hasChildElement([.child, .item]))
    }

    @Test
    func optionalChildElement_found() throws {
        let childText = TestNode(text: "hello")
        let child = TestNode(element: .child,
                             attributes: [:],
                             children: [childText])
        let node = TestNode(element: .root,
                            attributes: [:],
                            children: [child])
        let result: String? = try node.optionalChildElement(.child) { $0.value ?? "" }

        #expect(result == "hello")
    }

    @Test
    func optionalChildElement_notFound() throws {
        let node = TestNode(element: .root,
                            attributes: [:],
                            children: [])
        let result: String? = try node.optionalChildElement(.child) { $0.value ?? "" }

        #expect(result == nil)
    }

    @Test
    func optionalChildElements_found() throws {
        let child1 = TestNode(element: .child,
                              attributes: [.id: "1"],
                              children: [])
        let child2 = TestNode(element: .child,
                              attributes: [.id: "2"],
                              children: [])
        let node = TestNode(element: .root,
                            attributes: [:],
                            children: [child1, child2])

        let result: [String] = try node.optionalChildElements(.child) { $0.attributes?[.id] ?? "" }

        #expect(result == ["1", "2"])
    }

    @Test
    func optionalChildElements_notFound() throws {
        let node = TestNode(element: .root,
                            attributes: [:],
                            children: [])
        let result: [String] = try node.optionalChildElements(.child) { $0.value ?? "" }

        #expect(result.isEmpty)
    }

    @Test
    func requiredChildElement_found() throws {
        let childText = TestNode(text: "hello")
        let child = TestNode(element: .child,
                             attributes: [:],
                             children: [childText])
        let node = TestNode(element: .root,
                            attributes: [:],
                            children: [child])
        let result: String = try node.requiredChildElement(.child) { $0.value ?? "" }

        #expect(result == "hello")
    }

    @Test
    func requiredChildElement_notFound() {
        let node = TestNode(element: .root,
                            attributes: [:],
                            children: [])

        #expect(throws: TestNode.Error.self) {
            let _: String = try node.requiredChildElement(.child) { $0.value ?? "" }
        }
    }

    @Test
    func requiredChildElements_found() throws {
        let child1 = TestNode(element: .child,
                              attributes: [.id: "1"],
                              children: [])
        let child2 = TestNode(element: .child,
                              attributes: [.id: "2"],
                              children: [])
        let node = TestNode(element: .root,
                            attributes: [:],
                            children: [child1, child2])

        let result: [String] = try node.requiredChildElements(.child) { $0.attributes?[.id] ?? "" }

        #expect(result == ["1", "2"])
    }

    @Test
    func requiredChildElements_notFound() {
        let node = TestNode(element: .root,
                            attributes: [:],
                            children: [])

        #expect(throws: TestNode.Error.self) {
            let _: [String] = try node.requiredChildElements(.child) { $0.value ?? "" }
        }
    }

    @Test
    func unexpectedElement() {
        let node = TestNode(element: .root,
                            attributes: [:],
                            children: [])

        #expect(throws: TestNode.Error.self) {
            try node.unexpectedElement(.child)
        }
    }

    @Test
    func unexpectedElement_withArray() {
        let node = TestNode(element: .root,
                            attributes: [:],
                            children: [])

        #expect(throws: TestNode.Error.self) {
            try node.unexpectedElement([.child, .item])
        }
    }

    @Test
    func unexpectedRootElement() {
        let node = TestNode(element: .root,
                            attributes: [:],
                            children: [])

        #expect(throws: TestNode.Error.self) {
            try node.unexpectedRootElement()
        }
    }

    @Test
    func unsupportedRootElement() {
        let node = TestNode(element: .root,
                            attributes: [:],
                            children: [])

        #expect(throws: TestNode.Error.self) {
            try node.unsupportedRootElement()
        }
    }

    @Test
    func valueOfOptionalAttribute_found() throws {
        let node = TestNode(element: .root,
                            attributes: [.id: "123"],
                            children: [])
        let result: String? = try node.valueOfOptionalAttribute(.id)

        #expect(result == "123")
    }

    @Test
    func valueOfOptionalAttribute_invalid() {
        let node = TestNode(element: .root,
                            attributes: [.id: "abc"],
                            children: [])

        #expect(throws: TestNode.Error.self) {
            let _: Int? = try node.valueOfOptionalAttribute(.id) { Int($0) }
        }
    }

    @Test
    func valueOfOptionalAttribute_normalizesWhitespace() throws {
        let node = TestNode(element: .root,
                            attributes: [.id: "  hello  "],
                            children: [])
        let result: String? = try node.valueOfOptionalAttribute(.id)

        #expect(result == "hello")
    }

    @Test
    func valueOfOptionalAttribute_notFound() throws {
        let node = TestNode(element: .root,
                            attributes: [:],
                            children: [])
        let result: String? = try node.valueOfOptionalAttribute(.id)

        #expect(result == nil)
    }

    @Test
    func valueOfOptionalChildElement_found() throws {
        let childText = TestNode(text: "42")
        let child = TestNode(element: .child,
                             attributes: [:],
                             children: [childText])
        let node = TestNode(element: .root,
                            attributes: [:],
                            children: [child])
        let result: String? = try node.valueOfOptionalChildElement(.child)

        #expect(result == "42")
    }

    @Test
    func valueOfOptionalChildElement_invalid() {
        let childText = TestNode(text: "abc")
        let child = TestNode(element: .child,
                             attributes: [:],
                             children: [childText])
        let node = TestNode(element: .root,
                            attributes: [:],
                            children: [child])

        #expect(throws: TestNode.Error.self) {
            let _: Int? = try node.valueOfOptionalChildElement(.child) { Int($0) }
        }
    }

    @Test
    func valueOfOptionalChildElement_notFound() throws {
        let node = TestNode(element: .root,
                            attributes: [:],
                            children: [])
        let result: String? = try node.valueOfOptionalChildElement(.child)

        #expect(result == nil)
    }

    @Test
    func valueOfRequiredAttribute_found() throws {
        let node = TestNode(element: .root,
                            attributes: [.id: "123"],
                            children: [])
        let result: String = try node.valueOfRequiredAttribute(.id)

        #expect(result == "123")
    }

    @Test
    func valueOfRequiredAttribute_invalid() {
        let node = TestNode(element: .root,
                            attributes: [.id: "abc"],
                            children: [])

        #expect(throws: TestNode.Error.self) {
            let _: Int = try node.valueOfRequiredAttribute(.id) { Int($0) }
        }
    }

    @Test
    func valueOfRequiredAttribute_notFound() {
        let node = TestNode(element: .root,
                            attributes: [:],
                            children: [])

        #expect(throws: TestNode.Error.self) {
            let _: String = try node.valueOfRequiredAttribute(.id)
        }
    }

    @Test
    func valueOfRequiredChildElement_found() throws {
        let childText = TestNode(text: "42")
        let child = TestNode(element: .child,
                             attributes: [:],
                             children: [childText])
        let node = TestNode(element: .root,
                            attributes: [:],
                            children: [child])
        let result: String = try node.valueOfRequiredChildElement(.child)

        #expect(result == "42")
    }

    @Test
    func valueOfRequiredChildElement_invalid() {
        let childText = TestNode(text: "abc")
        let child = TestNode(element: .child,
                             attributes: [:],
                             children: [childText])
        let node = TestNode(element: .root,
                            attributes: [:],
                            children: [child])

        #expect(throws: TestNode.Error.self) {
            let _: Int = try node.valueOfRequiredChildElement(.child) { Int($0) }
        }
    }

    @Test
    func valueOfRequiredChildElement_notFound() {
        let node = TestNode(element: .root,
                            attributes: [:],
                            children: [])

        #expect(throws: TestNode.Error.self) {
            let _: String = try node.valueOfRequiredChildElement(.child)
        }
    }
}
