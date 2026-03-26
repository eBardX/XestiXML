// © 2026 John Gary Pusey (see LICENSE.md)

import Testing
@testable import XestiXML

private enum TestElement: String, XMLElement {
    case child
    case item
    case other
    case root
}

private enum TestAttribute: String, XMLAttribute {
    case id
    case name
}

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
    func test_allChildElementsMatchingMultiple() {
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
    func test_allChildElementsMatchingSingle() {
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
    func test_allChildElementsOnTextNode() {
        let node = XMLNode<TestElement, TestAttribute>(text: "text")

        #expect(node.allChildElements().isEmpty)
    }

    @Test
    func test_descriptionOfElementNode() {
        let node = XMLNode<TestElement, TestAttribute>(element: .root,
                                                       attributes: [:],
                                                       children: [])

        #expect(node.description.contains("<root>"))
    }

    @Test
    func test_descriptionOfElementNodeWithAttributes() {
        let node = XMLNode<TestElement, TestAttribute>(element: .root,
                                                       attributes: [.id: "1"],
                                                       children: [])

        #expect(node.description.contains("id=\"1\""))
    }

    @Test
    func test_descriptionOfElementNodeWithChildren() {
        let child = XMLNode<TestElement, TestAttribute>(text: "hello")
        let node = XMLNode(element: .root,
                           attributes: [:],
                           children: [child])

        #expect(node.description.contains("<root>"))
        #expect(node.description.contains("hello"))
    }

    @Test
    func test_descriptionOfTextNode() {
        let node = XMLNode<TestElement, TestAttribute>(text: "hello")

        #expect(node.description == "\"hello\"")
    }

    @Test
    func test_elementNodeAttributes() {
        let node = XMLNode<TestElement, TestAttribute>(element: .root,
                                                       attributes: [.id: "1"],
                                                       children: [])

        #expect(node.attributes == [.id: "1"])
    }

    @Test
    func test_elementNodeChildren() {
        let child = XMLNode<TestElement, TestAttribute>(text: "hello")
        let node = XMLNode(element: .root,
                           attributes: [:],
                           children: [child])

        #expect(node.children?.count == 1)
    }

    @Test
    func test_elementNodeElement() {
        let node = XMLNode<TestElement, TestAttribute>(element: .root,
                                                       attributes: [:],
                                                       children: [])

        #expect(node.element == .root)
    }

    @Test
    func test_elementNodeIsElement() {
        let node = XMLNode<TestElement, TestAttribute>(element: .root,
                                                       attributes: [:],
                                                       children: [])

        #expect(node.isElement)
    }

    @Test
    func test_elementNodeIsNotText() {
        let node = XMLNode<TestElement, TestAttribute>(element: .root,
                                                       attributes: [:],
                                                       children: [])

        #expect(!node.isText)
    }

    @Test
    func test_elementNodeName() {
        let node = XMLNode<TestElement, TestAttribute>(element: .root,
                                                       attributes: [:],
                                                       children: [])

        #expect(node.name == "root")
    }

    @Test
    func test_elementNodeURI() {
        let node = XMLNode<TestElement, TestAttribute>(element: .root,
                                                       attributes: [:],
                                                       children: [])

        #expect(node.uri == nil)
    }

    @Test
    func test_elementNodeValueFromNestedElements() {
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
    func test_elementNodeValueFromTextChildren() {
        let text1 = XMLNode<TestElement, TestAttribute>(text: "hello ")
        let text2 = XMLNode<TestElement, TestAttribute>(text: "world")
        let node = XMLNode(element: .root,
                           attributes: [:],
                           children: [text1, text2])

        #expect(node.value == "hello world")
    }

    @Test
    func test_elementNodeValueWithNoChildren() {
        let node = XMLNode<TestElement, TestAttribute>(element: .root,
                                                       attributes: [:],
                                                       children: [])

        #expect(node.value?.isEmpty == true)
    }

    @Test
    func test_firstChildElementFound() {
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
    func test_firstChildElementFromArray() {
        let child = XMLNode<TestElement, TestAttribute>(element: .item,
                                                        attributes: [:],
                                                        children: [])
        let node = XMLNode(element: .root,
                           attributes: [:],
                           children: [child])

        #expect(node.firstChildElement([.child, .item]) != nil)
    }

    @Test
    func test_firstChildElementNotFound() {
        let child = XMLNode<TestElement, TestAttribute>(element: .child,
                                                        attributes: [:],
                                                        children: [])
        let node = XMLNode(element: .root,
                           attributes: [:],
                           children: [child])

        #expect(node.firstChildElement(.item) == nil)
    }

    @Test
    func test_firstChildElementOnTextNode() {
        let node = XMLNode<TestElement, TestAttribute>(text: "text")

        #expect(node.firstChildElement(.child) == nil)
    }

    @Test
    func test_isElementFromArray() {
        let node = XMLNode<TestElement, TestAttribute>(element: .root,
                                                       attributes: [:],
                                                       children: [])

        #expect(node.isElement([.root, .child]))
    }

    @Test
    func test_isElementMatching() {
        let node = XMLNode<TestElement, TestAttribute>(element: .root,
                                                       attributes: [:],
                                                       children: [])

        #expect(node.isElement(.root))
    }

    @Test
    func test_isElementNotMatching() {
        let node = XMLNode<TestElement, TestAttribute>(element: .root,
                                                       attributes: [:],
                                                       children: [])

        #expect(!node.isElement(.child))
    }

    @Test
    func test_isElementOnTextNode() {
        let node = XMLNode<TestElement, TestAttribute>(text: "text")

        #expect(!node.isElement(.root))
    }

    @Test
    func test_textNodeAttributes() {
        let node = XMLNode<TestElement, TestAttribute>(text: "hello")

        #expect(node.attributes == nil)
    }

    @Test
    func test_textNodeChildren() {
        let node = XMLNode<TestElement, TestAttribute>(text: "hello")

        #expect(node.children == nil)
    }

    @Test
    func test_textNodeElement() {
        let node = XMLNode<TestElement, TestAttribute>(text: "hello")

        #expect(node.element == nil)
    }

    @Test
    func test_textNodeIsNotElement() {
        let node = XMLNode<TestElement, TestAttribute>(text: "hello")

        #expect(!node.isElement)
    }

    @Test
    func test_textNodeIsText() {
        let node = XMLNode<TestElement, TestAttribute>(text: "hello")

        #expect(node.isText)
    }

    @Test
    func test_textNodeName() {
        let node = XMLNode<TestElement, TestAttribute>(text: "hello")

        #expect(node.name == nil)
    }

    @Test
    func test_textNodeURI() {
        let node = XMLNode<TestElement, TestAttribute>(text: "hello")

        #expect(node.uri == nil)
    }

    @Test
    func test_textNodeValue() {
        let node = XMLNode<TestElement, TestAttribute>(text: "hello")

        #expect(node.value == "hello")
    }
}
