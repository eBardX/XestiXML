// © 2026 John Gary Pusey (see LICENSE.md)

import Testing
@testable import XestiXML

struct XMLNodeTests {
}

// MARK: -

extension XMLNodeTests {
    @Test
    func test_allChildElements() {
        let child1 = XMLNode<TestElement, TestAttribute>(element: .child,
                                                         attributes: [:],
                                                         children: [])
        let text = XMLNode<TestElement, TestAttribute>(text: "text")
        let child2 = XMLNode<TestElement, TestAttribute>(element: .item,
                                                         attributes: [:],
                                                         children: [])
        let node = XMLNode(element: .root,
                           attributes: [:],
                           children: [child1, text, child2])

        #expect(node.allChildElements().count == 2)
    }

    @Test
    func test_allChildElements_matchingMultiple() {
        let child1 = XMLNode<TestElement, TestAttribute>(element: .child,
                                                         attributes: [:],
                                                         children: [])
        let child2 = XMLNode<TestElement, TestAttribute>(element: .item,
                                                         attributes: [:],
                                                         children: [])
        let child3 = XMLNode<TestElement, TestAttribute>(element: .other,
                                                         attributes: [:],
                                                         children: [])
        let node = XMLNode(element: .root,
                           attributes: [:],
                           children: [child1, child2, child3])

        #expect(node.allChildElements([.child, .item]).count == 2)
    }

    @Test
    func test_allChildElements_matchingSingle() {
        let child1 = XMLNode<TestElement, TestAttribute>(element: .child,
                                                         attributes: [:],
                                                         children: [])
        let child2 = XMLNode<TestElement, TestAttribute>(element: .item,
                                                         attributes: [:],
                                                         children: [])
        let child3 = XMLNode<TestElement, TestAttribute>(element: .child,
                                                         attributes: [:],
                                                         children: [])
        let node = XMLNode(element: .root,
                           attributes: [:],
                           children: [child1, child2, child3])

        #expect(node.allChildElements(.child).count == 2)
    }

    @Test
    func test_allChildElements_textNode() {
        let node = XMLNode<TestElement, TestAttribute>(text: "text")

        #expect(node.allChildElements().isEmpty)
    }

    @Test
    func test_attributes_elementNode() {
        let node = XMLNode<TestElement, TestAttribute>(element: .root,
                                                       attributes: [.id: "1"],
                                                       children: [])

        #expect(node.attributes == [.id: "1"])
    }

    @Test
    func test_attributes_textNode() {
        let node = XMLNode<TestElement, TestAttribute>(text: "hello")

        #expect(node.attributes == nil)
    }

    @Test
    func test_children_elementNode() {
        let child = XMLNode<TestElement, TestAttribute>(text: "hello")
        let node = XMLNode(element: .root,
                           attributes: [:],
                           children: [child])

        #expect(node.children?.count == 1)
    }

    @Test
    func test_children_textNode() {
        let node = XMLNode<TestElement, TestAttribute>(text: "hello")

        #expect(node.children == nil)
    }

    @Test
    func test_description_elementNode() {
        let node = XMLNode<TestElement, TestAttribute>(element: .root,
                                                       attributes: [:],
                                                       children: [])

        #expect(node.description.contains("<root>"))
    }

    @Test
    func test_description_elementNodeWithAttributes() {
        let node = XMLNode<TestElement, TestAttribute>(element: .root,
                                                       attributes: [.id: "1"],
                                                       children: [])

        #expect(node.description.contains("id=\"1\""))
    }

    @Test
    func test_description_elementNodeWithChildren() {
        let child = XMLNode<TestElement, TestAttribute>(text: "hello")
        let node = XMLNode(element: .root,
                           attributes: [:],
                           children: [child])

        #expect(node.description.contains("<root>"))
        #expect(node.description.contains("hello"))
    }

    @Test
    func test_description_textNode() {
        let node = XMLNode<TestElement, TestAttribute>(text: "hello")

        #expect(node.description == "\"hello\"")
    }

    @Test
    func test_element_elementNode() {
        let node = XMLNode<TestElement, TestAttribute>(element: .root,
                                                       attributes: [:],
                                                       children: [])

        #expect(node.element == .root)
    }

    @Test
    func test_element_textNode() {
        let node = XMLNode<TestElement, TestAttribute>(text: "hello")

        #expect(node.element == nil)
    }

    @Test
    func test_firstChildElement_found() {
        let child1 = XMLNode<TestElement, TestAttribute>(element: .child,
                                                         attributes: [:],
                                                         children: [])
        let child2 = XMLNode<TestElement, TestAttribute>(element: .item,
                                                         attributes: [:],
                                                         children: [])
        let node = XMLNode(element: .root,
                           attributes: [:],
                           children: [child1, child2])

        #expect(node.firstChildElement(.item) != nil)
        #expect(node.firstChildElement(.item)?.element == .item)
    }

    @Test
    func test_firstChildElement_fromArray() {
        let child = XMLNode<TestElement, TestAttribute>(element: .item,
                                                        attributes: [:],
                                                        children: [])
        let node = XMLNode(element: .root,
                           attributes: [:],
                           children: [child])

        #expect(node.firstChildElement([.child, .item]) != nil)
    }

    @Test
    func test_firstChildElement_notFound() {
        let child = XMLNode<TestElement, TestAttribute>(element: .child,
                                                        attributes: [:],
                                                        children: [])
        let node = XMLNode(element: .root,
                           attributes: [:],
                           children: [child])

        #expect(node.firstChildElement(.item) == nil)
    }

    @Test
    func test_firstChildElement_textNode() {
        let node = XMLNode<TestElement, TestAttribute>(text: "text")

        #expect(node.firstChildElement(.child) == nil)
    }

    @Test
    func test_isElement_elementNode() {
        let node = XMLNode<TestElement, TestAttribute>(element: .root,
                                                       attributes: [:],
                                                       children: [])

        #expect(node.isElement)
    }

    @Test
    func test_isElement_fromArray() {
        let node = XMLNode<TestElement, TestAttribute>(element: .root,
                                                       attributes: [:],
                                                       children: [])

        #expect(node.isElement([.root, .child]))
    }

    @Test
    func test_isElement_matching() {
        let node = XMLNode<TestElement, TestAttribute>(element: .root,
                                                       attributes: [:],
                                                       children: [])

        #expect(node.isElement(.root))
    }

    @Test
    func test_isElement_notMatching() {
        let node = XMLNode<TestElement, TestAttribute>(element: .root,
                                                       attributes: [:],
                                                       children: [])

        #expect(!node.isElement(.child))
    }

    @Test
    func test_isElement_textNode() {
        let node = XMLNode<TestElement, TestAttribute>(text: "text")

        #expect(!node.isElement(.root))
    }

    @Test
    func test_isElement_textNodeIsFalse() {
        let node = XMLNode<TestElement, TestAttribute>(text: "hello")

        #expect(!node.isElement)
    }

    @Test
    func test_isText_elementNode() {
        let node = XMLNode<TestElement, TestAttribute>(element: .root,
                                                       attributes: [:],
                                                       children: [])

        #expect(!node.isText)
    }

    @Test
    func test_isText_textNode() {
        let node = XMLNode<TestElement, TestAttribute>(text: "hello")

        #expect(node.isText)
    }

    @Test
    func test_name_elementNode() {
        let node = XMLNode<TestElement, TestAttribute>(element: .root,
                                                       attributes: [:],
                                                       children: [])

        #expect(node.name == "root")
    }

    @Test
    func test_name_textNode() {
        let node = XMLNode<TestElement, TestAttribute>(text: "hello")

        #expect(node.name == nil)
    }

    @Test
    func test_uri_elementNode() {
        let node = XMLNode<TestElement, TestAttribute>(element: .root,
                                                       attributes: [:],
                                                       children: [])

        #expect(node.uri == nil)
    }

    @Test
    func test_uri_textNode() {
        let node = XMLNode<TestElement, TestAttribute>(text: "hello")

        #expect(node.uri == nil)
    }

    @Test
    func test_value_elementNodeNestedElements() {
        let innerText = XMLNode<TestElement, TestAttribute>(text: "inner")
        let inner = XMLNode(element: .child,
                            attributes: [:],
                            children: [innerText])
        let outerText = XMLNode<TestElement, TestAttribute>(text: "outer")
        let node = XMLNode(element: .root,
                           attributes: [:],
                           children: [outerText, inner])

        #expect(node.value == "outerinner")
    }

    @Test
    func test_value_elementNodeNoChildren() {
        let node = XMLNode<TestElement, TestAttribute>(element: .root,
                                                       attributes: [:],
                                                       children: [])

        #expect(node.value?.isEmpty == true)
    }

    @Test
    func test_value_elementNodeTextChildren() {
        let text1 = XMLNode<TestElement, TestAttribute>(text: "hello ")
        let text2 = XMLNode<TestElement, TestAttribute>(text: "world")
        let node = XMLNode(element: .root,
                           attributes: [:],
                           children: [text1, text2])

        #expect(node.value == "hello world")
    }

    @Test
    func test_value_textNode() {
        let node = XMLNode<TestElement, TestAttribute>(text: "hello")

        #expect(node.value == "hello")
    }
}
