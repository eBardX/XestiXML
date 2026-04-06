// © 2026 John Gary Pusey (see LICENSE.md)

import Testing
@testable import XestiXML

struct XMLNodeConvenienceTests {
}

// MARK: -

extension XMLNodeConvenienceTests {
    @Test
    func test_expectElement_matching() throws {
        let node = XMLNode<TestElement, TestAttribute>(element: .root,
                                                       attributes: [:],
                                                       children: [])

        try node.expectElement(.root)
    }

    @Test
    func test_expectElement_notMatching() {
        let node = XMLNode<TestElement, TestAttribute>(element: .root,
                                                       attributes: [:],
                                                       children: [])

        #expect(throws: XMLError.self) {
            try node.expectElement(.child)
        }
    }

    @Test
    func test_hasChildElement_false() {
        let child = XMLNode<TestElement, TestAttribute>(element: .child,
                                                        attributes: [:],
                                                        children: [])
        let node = XMLNode(element: .root,
                           attributes: [:],
                           children: [child])

        #expect(!node.hasChildElement(.item))
    }

    @Test
    func test_hasChildElement_true() {
        let child = XMLNode<TestElement, TestAttribute>(element: .child,
                                                        attributes: [:],
                                                        children: [])
        let node = XMLNode(element: .root,
                           attributes: [:],
                           children: [child])

        #expect(node.hasChildElement(.child))
    }

    @Test
    func test_hasChildElement_withArray() {
        let child = XMLNode<TestElement, TestAttribute>(element: .child,
                                                        attributes: [:],
                                                        children: [])
        let node = XMLNode(element: .root,
                           attributes: [:],
                           children: [child])

        #expect(node.hasChildElement([.child, .item]))
    }

    @Test
    func test_optionalChildElement_found() throws {
        let childText = XMLNode<TestElement, TestAttribute>(text: "hello")
        let child = XMLNode(element: .child,
                            attributes: [:],
                            children: [childText])
        let node = XMLNode(element: .root,
                           attributes: [:],
                           children: [child])
        let result: String? = try node.optionalChildElement(.child) { $0.value ?? "" }

        #expect(result == "hello")
    }

    @Test
    func test_optionalChildElement_notFound() throws {
        let node = XMLNode<TestElement, TestAttribute>(element: .root,
                                                       attributes: [:],
                                                       children: [])
        let result: String? = try node.optionalChildElement(.child) { $0.value ?? "" }

        #expect(result == nil)
    }

    @Test
    func test_optionalChildElements_found() throws {
        let child1 = XMLNode<TestElement, TestAttribute>(element: .child,
                                                         attributes: [.id: "1"],
                                                         children: [])
        let child2 = XMLNode<TestElement, TestAttribute>(element: .child,
                                                         attributes: [.id: "2"],
                                                         children: [])
        let node = XMLNode(element: .root,
                           attributes: [:],
                           children: [child1, child2])

        let result: [String] = try node.optionalChildElements(.child) { $0.attributes?[.id] ?? "" }

        #expect(result == ["1", "2"])
    }

    @Test
    func test_optionalChildElements_notFound() throws {
        let node = XMLNode<TestElement, TestAttribute>(element: .root,
                                                       attributes: [:],
                                                       children: [])
        let result: [String] = try node.optionalChildElements(.child) { $0.value ?? "" }

        #expect(result.isEmpty)
    }

    @Test
    func test_requiredChildElement_found() throws {
        let childText = XMLNode<TestElement, TestAttribute>(text: "hello")
        let child = XMLNode(element: .child,
                            attributes: [:],
                            children: [childText])
        let node = XMLNode(element: .root,
                           attributes: [:],
                           children: [child])
        let result: String = try node.requiredChildElement(.child) { $0.value ?? "" }

        #expect(result == "hello")
    }

    @Test
    func test_requiredChildElement_notFound() {
        let node = XMLNode<TestElement, TestAttribute>(element: .root,
                                                       attributes: [:],
                                                       children: [])

        #expect(throws: XMLError.self) {
            let _: String = try node.requiredChildElement(.child) { $0.value ?? "" }
        }
    }

    @Test
    func test_requiredChildElements_found() throws {
        let child1 = XMLNode<TestElement, TestAttribute>(element: .child,
                                                         attributes: [.id: "1"],
                                                         children: [])
        let child2 = XMLNode<TestElement, TestAttribute>(element: .child,
                                                         attributes: [.id: "2"],
                                                         children: [])
        let node = XMLNode(element: .root,
                           attributes: [:],
                           children: [child1, child2])

        let result: [String] = try node.requiredChildElements(.child) { $0.attributes?[.id] ?? "" }

        #expect(result == ["1", "2"])
    }

    @Test
    func test_requiredChildElements_notFound() {
        let node = XMLNode<TestElement, TestAttribute>(element: .root,
                                                       attributes: [:],
                                                       children: [])

        #expect(throws: XMLError.self) {
            let _: [String] = try node.requiredChildElements(.child) { $0.value ?? "" }
        }
    }

    @Test
    func test_unexpectedRootElement() {
        let node = XMLNode<TestElement, TestAttribute>(element: .root,
                                                       attributes: [:],
                                                       children: [])

        #expect(throws: XMLError.self) {
            try node.unexpectedRootElement()
        }
    }

    @Test
    func test_unsupportedRootElement() {
        let node = XMLNode<TestElement, TestAttribute>(element: .root,
                                                       attributes: [:],
                                                       children: [])

        #expect(throws: XMLError.self) {
            try node.unsupportedRootElement()
        }
    }

    @Test
    func test_valueOfOptionalAttribute_found() throws {
        let node = XMLNode<TestElement, TestAttribute>(element: .root,
                                                       attributes: [.id: "123"],
                                                       children: [])
        let result: String? = try node.valueOfOptionalAttribute(.id)

        #expect(result == "123")
    }

    @Test
    func test_valueOfOptionalAttribute_invalid() {
        let node = XMLNode<TestElement, TestAttribute>(element: .root,
                                                       attributes: [.id: "abc"],
                                                       children: [])

        #expect(throws: XMLError.self) {
            let _: Int? = try node.valueOfOptionalAttribute(.id) { Int($0) }
        }
    }

    @Test
    func test_valueOfOptionalAttribute_normalizesWhitespace() throws {
        let node = XMLNode<TestElement, TestAttribute>(element: .root,
                                                       attributes: [.id: "  hello  "],
                                                       children: [])
        let result: String? = try node.valueOfOptionalAttribute(.id)

        #expect(result == "hello")
    }

    @Test
    func test_valueOfOptionalAttribute_notFound() throws {
        let node = XMLNode<TestElement, TestAttribute>(element: .root,
                                                       attributes: [:],
                                                       children: [])
        let result: String? = try node.valueOfOptionalAttribute(.id)

        #expect(result == nil)
    }

    @Test
    func test_valueOfOptionalChildElement_found() throws {
        let childText = XMLNode<TestElement, TestAttribute>(text: "42")
        let child = XMLNode(element: .child,
                            attributes: [:],
                            children: [childText])
        let node = XMLNode(element: .root,
                           attributes: [:],
                           children: [child])
        let result: String? = try node.valueOfOptionalChildElement(.child)

        #expect(result == "42")
    }

    @Test
    func test_valueOfOptionalChildElement_invalid() {
        let childText = XMLNode<TestElement, TestAttribute>(text: "abc")
        let child = XMLNode(element: .child,
                            attributes: [:],
                            children: [childText])
        let node = XMLNode(element: .root,
                           attributes: [:],
                           children: [child])

        #expect(throws: XMLError.self) {
            let _: Int? = try node.valueOfOptionalChildElement(.child) { Int($0) }
        }
    }

    @Test
    func test_valueOfOptionalChildElement_notFound() throws {
        let node = XMLNode<TestElement, TestAttribute>(element: .root,
                                                       attributes: [:],
                                                       children: [])
        let result: String? = try node.valueOfOptionalChildElement(.child)

        #expect(result == nil)
    }

    @Test
    func test_valueOfRequiredAttribute_found() throws {
        let node = XMLNode<TestElement, TestAttribute>(element: .root,
                                                       attributes: [.id: "123"],
                                                       children: [])
        let result: String = try node.valueOfRequiredAttribute(.id)

        #expect(result == "123")
    }

    @Test
    func test_valueOfRequiredAttribute_invalid() {
        let node = XMLNode<TestElement, TestAttribute>(element: .root,
                                                       attributes: [.id: "abc"],
                                                       children: [])

        #expect(throws: XMLError.self) {
            let _: Int = try node.valueOfRequiredAttribute(.id) { Int($0) }
        }
    }

    @Test
    func test_valueOfRequiredAttribute_notFound() {
        let node = XMLNode<TestElement, TestAttribute>(element: .root,
                                                       attributes: [:],
                                                       children: [])

        #expect(throws: XMLError.self) {
            let _: String = try node.valueOfRequiredAttribute(.id)
        }
    }

    @Test
    func test_valueOfRequiredChildElement_found() throws {
        let childText = XMLNode<TestElement, TestAttribute>(text: "42")
        let child = XMLNode(element: .child,
                            attributes: [:],
                            children: [childText])
        let node = XMLNode(element: .root,
                           attributes: [:],
                           children: [child])
        let result: String = try node.valueOfRequiredChildElement(.child)

        #expect(result == "42")
    }

    @Test
    func test_valueOfRequiredChildElement_invalid() {
        let childText = XMLNode<TestElement, TestAttribute>(text: "abc")
        let child = XMLNode(element: .child,
                            attributes: [:],
                            children: [childText])
        let node = XMLNode(element: .root,
                           attributes: [:],
                           children: [child])

        #expect(throws: XMLError.self) {
            let _: Int = try node.valueOfRequiredChildElement(.child) { Int($0) }
        }
    }

    @Test
    func test_valueOfRequiredChildElement_notFound() {
        let node = XMLNode<TestElement, TestAttribute>(element: .root,
                                                       attributes: [:],
                                                       children: [])

        #expect(throws: XMLError.self) {
            let _: String = try node.valueOfRequiredChildElement(.child)
        }
    }
}
