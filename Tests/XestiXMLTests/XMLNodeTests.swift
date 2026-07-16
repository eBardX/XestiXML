// © 2026 John Gary Pusey (see LICENSE.md)

import Testing
@testable import XestiXML

struct XMLNodeTests {
}

// MARK: -

extension XMLNodeTests {
    @Test
    func allChildElements() {
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
    func allChildElements_matchingMultiple() {
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
    func allChildElements_matchingSingle() {
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
    func allChildElements_textNode() {
        let node = XMLNode<TestElement, TestAttribute>(text: "text")

        #expect(node.allChildElements().isEmpty)
    }

    @Test
    func attributes_elementNode() {
        let node = XMLNode<TestElement, TestAttribute>(element: .root,
                                                       attributes: [.id: "1"],
                                                       children: [])

        #expect(node.attributes == [.id: "1"])
    }

    @Test
    func attributes_textNode() {
        let node = XMLNode<TestElement, TestAttribute>(text: "hello")

        #expect(node.attributes == nil)
    }

    @Test
    func children_elementNode() {
        let child = XMLNode<TestElement, TestAttribute>(text: "hello")
        let node = XMLNode(element: .root,
                           attributes: [:],
                           children: [child])

        #expect(node.children?.count == 1)
    }

    @Test
    func children_textNode() {
        let node = XMLNode<TestElement, TestAttribute>(text: "hello")

        #expect(node.children == nil)
    }

    @Test
    func description_elementNode() {
        let node = XMLNode<TestElement, TestAttribute>(element: .root,
                                                       attributes: [:],
                                                       children: [])

        #expect(node.description.contains("<root>"))
    }

    @Test
    func description_elementNodeWithAttributes() {
        let node = XMLNode<TestElement, TestAttribute>(element: .root,
                                                       attributes: [.id: "1"],
                                                       children: [])

        #expect(node.description.contains("id=\"1\""))
    }

    @Test
    func description_elementNodeWithChildren() {
        let child = XMLNode<TestElement, TestAttribute>(text: "hello")
        let node = XMLNode(element: .root,
                           attributes: [:],
                           children: [child])

        #expect(node.description.contains("<root>"))
        #expect(node.description.contains("hello"))
    }

    @Test
    func description_textNode() {
        let node = XMLNode<TestElement, TestAttribute>(text: "hello")

        #expect(node.description == "\"hello\"")
    }

    @Test
    func element_elementNode() {
        let node = XMLNode<TestElement, TestAttribute>(element: .root,
                                                       attributes: [:],
                                                       children: [])

        #expect(node.element == .root)
    }

    @Test
    func element_textNode() {
        let node = XMLNode<TestElement, TestAttribute>(text: "hello")

        #expect(node.element == nil)
    }

    @Test
    func firstChildElement_found() {
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
    func firstChildElement_fromArray() {
        let child = XMLNode<TestElement, TestAttribute>(element: .item,
                                                        attributes: [:],
                                                        children: [])
        let node = XMLNode(element: .root,
                           attributes: [:],
                           children: [child])

        #expect(node.firstChildElement([.child, .item]) != nil)
    }

    @Test
    func firstChildElement_notFound() {
        let child = XMLNode<TestElement, TestAttribute>(element: .child,
                                                        attributes: [:],
                                                        children: [])
        let node = XMLNode(element: .root,
                           attributes: [:],
                           children: [child])

        #expect(node.firstChildElement(.item) == nil)
    }

    @Test
    func firstChildElement_textNode() {
        let node = XMLNode<TestElement, TestAttribute>(text: "text")

        #expect(node.firstChildElement(.child) == nil)
    }

    @Test
    func isElement_elementNode() {
        let node = XMLNode<TestElement, TestAttribute>(element: .root,
                                                       attributes: [:],
                                                       children: [])

        #expect(node.isElement)
    }

    @Test
    func isElement_fromArray() {
        let node = XMLNode<TestElement, TestAttribute>(element: .root,
                                                       attributes: [:],
                                                       children: [])

        #expect(node.isElement([.root, .child]))
    }

    @Test
    func isElement_matching() {
        let node = XMLNode<TestElement, TestAttribute>(element: .root,
                                                       attributes: [:],
                                                       children: [])

        #expect(node.isElement(.root))
    }

    @Test
    func isElement_notMatching() {
        let node = XMLNode<TestElement, TestAttribute>(element: .root,
                                                       attributes: [:],
                                                       children: [])

        #expect(!node.isElement(.child))
    }

    @Test
    func isElement_textNode() {
        let node = XMLNode<TestElement, TestAttribute>(text: "text")

        #expect(!node.isElement(.root))
    }

    @Test
    func isElement_textNodeIsFalse() {
        let node = XMLNode<TestElement, TestAttribute>(text: "hello")

        #expect(!node.isElement)
    }

    @Test
    func isText_elementNode() {
        let node = XMLNode<TestElement, TestAttribute>(element: .root,
                                                       attributes: [:],
                                                       children: [])

        #expect(!node.isText)
    }

    @Test
    func isText_textNode() {
        let node = XMLNode<TestElement, TestAttribute>(text: "hello")

        #expect(node.isText)
    }

    @Test
    func name_elementNode() {
        let node = XMLNode<TestElement, TestAttribute>(element: .root,
                                                       attributes: [:],
                                                       children: [])

        #expect(node.name == "root")
    }

    @Test
    func name_textNode() {
        let node = XMLNode<TestElement, TestAttribute>(text: "hello")

        #expect(node.name == nil)
    }

    @Test
    func uri_elementNode() {
        let node = XMLNode<TestElement, TestAttribute>(element: .root,
                                                       attributes: [:],
                                                       children: [])

        #expect(node.uri == nil)
    }

    @Test
    func uri_textNode() {
        let node = XMLNode<TestElement, TestAttribute>(text: "hello")

        #expect(node.uri == nil)
    }

    @Test
    func value_elementNodeNestedElements() {
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
    func value_elementNodeNoChildren() {
        let node = XMLNode<TestElement, TestAttribute>(element: .root,
                                                       attributes: [:],
                                                       children: [])

        #expect(node.value?.isEmpty == true)
    }

    @Test
    func value_elementNodeTextChildren() {
        let text1 = XMLNode<TestElement, TestAttribute>(text: "hello ")
        let text2 = XMLNode<TestElement, TestAttribute>(text: "world")
        let node = XMLNode(element: .root,
                           attributes: [:],
                           children: [text1, text2])

        #expect(node.value == "hello world")
    }

    @Test
    func value_textNode() {
        let node = XMLNode<TestElement, TestAttribute>(text: "hello")

        #expect(node.value == "hello")
    }
}
