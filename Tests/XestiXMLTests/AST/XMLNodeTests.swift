// © 2026 John Gary Pusey (see LICENSE.md)

import Testing
@testable import XestiXML

struct XMLNodeTests {
}

// MARK: -

extension XMLNodeTests {
    @Test
    func allChildElements() {
        let child1 = TestNode(element: .child,
                              attributes: [:],
                              children: [])
        let text = TestNode(text: "text")
        let child2 = TestNode(element: .item,
                              attributes: [:],
                              children: [])
        let node = TestNode(element: .root,
                            attributes: [:],
                            children: [child1, text, child2])

        #expect(node.allChildElements().count == 2)
    }

    @Test
    func allChildElements_matchingMultiple() {
        let child1 = TestNode(element: .child,
                              attributes: [:],
                              children: [])
        let child2 = TestNode(element: .item,
                              attributes: [:],
                              children: [])
        let child3 = TestNode(element: .other,
                              attributes: [:],
                              children: [])
        let node = TestNode(element: .root,
                            attributes: [:],
                            children: [child1, child2, child3])

        #expect(node.allChildElements([.child, .item]).count == 2)
    }

    @Test
    func allChildElements_matchingSingle() {
        let child1 = TestNode(element: .child,
                              attributes: [:],
                              children: [])
        let child2 = TestNode(element: .item,
                              attributes: [:],
                              children: [])
        let child3 = TestNode(element: .child,
                              attributes: [:],
                              children: [])
        let node = TestNode(element: .root,
                            attributes: [:],
                            children: [child1, child2, child3])

        #expect(node.allChildElements(.child).count == 2)
    }

    @Test
    func allChildElements_textNode() {
        let node = TestNode(text: "text")

        #expect(node.allChildElements().isEmpty)
    }

    @Test
    func attributes_elementNode() {
        let node = TestNode(element: .root,
                            attributes: [.id: "1"],
                            children: [])

        #expect(node.attributes == [.id: "1"])
    }

    @Test
    func attributes_textNode() {
        let node = TestNode(text: "hello")

        #expect(node.attributes == nil)
    }

    @Test
    func children_elementNode() {
        let child = TestNode(text: "hello")
        let node = TestNode(element: .root,
                            attributes: [:],
                            children: [child])

        #expect(node.children?.count == 1)
    }

    @Test
    func children_textNode() {
        let node = TestNode(text: "hello")

        #expect(node.children == nil)
    }

    @Test
    func comment_accessors() {
        let node = TestNode(comment: " note ")

        #expect(node.isComment)
        #expect(node.comment == " note ")
        #expect(!node.isElement)
        #expect(!node.isText)
        #expect(!node.isProcessingInstruction)
        #expect(node.element == nil)
        #expect(node.children == nil)
        #expect(node.name == nil)
        #expect(node.target == nil)
    }

    @Test
    func comment_description() {
        #expect(TestNode(comment: " note ").description == "<!-- note -->")
    }

    @Test
    func comment_doesNotContributeToElementValue() {
        let node = TestNode(element: .root,
                            attributes: [:],
                            children: [TestNode(text: "a"),
                                       TestNode(comment: " note "),
                                       TestNode(text: "b")])

        #expect(node.value == "ab")
    }

    //  A comment is not character data, so it contributes nothing to any value.
    @Test
    func comment_hasNilValue() {
        #expect(TestNode(comment: " note ").value == nil)
    }

    @Test
    func comment_isNotACapturedChildElement() {
        let node = TestNode(element: .root,
                            attributes: [:],
                            children: [TestNode(comment: " note "),
                                       TestNode(element: .child,
                                                attributes: [:],
                                                children: [])])

        #expect(node.children?.count == 2)
        #expect(node.allChildElements().count == 1)
    }

    @Test
    func description_elementNode() {
        let node = TestNode(element: .root,
                            attributes: [:],
                            children: [])

        #expect(node.description.contains("<root>"))
    }

    @Test
    func description_elementNodeWithAttributes() {
        let node = TestNode(element: .root,
                            attributes: [.id: "1"],
                            children: [])

        #expect(node.description.contains("id=\"1\""))
    }

    @Test
    func description_elementNodeWithChildren() {
        let child = TestNode(text: "hello")
        let node = TestNode(element: .root,
                            attributes: [:],
                            children: [child])

        #expect(node.description.contains("<root>"))
        #expect(node.description.contains("hello"))
    }

    @Test
    func description_textNode() {
        let node = TestNode(text: "hello")

        #expect(node.description == "\"hello\"")
    }

    @Test
    func element_elementNode() {
        let node = TestNode(element: .root,
                            attributes: [:],
                            children: [])

        #expect(node.element == .root)
    }

    @Test
    func element_textNode() {
        let node = TestNode(text: "hello")

        #expect(node.element == nil)
    }

    @Test
    func firstChildElement_found() {
        let child1 = TestNode(element: .child,
                              attributes: [:],
                              children: [])
        let child2 = TestNode(element: .item,
                              attributes: [:],
                              children: [])
        let node = TestNode(element: .root,
                            attributes: [:],
                            children: [child1, child2])

        #expect(node.firstChildElement(.item) != nil)
        #expect(node.firstChildElement(.item)?.element == .item)
    }

    @Test
    func firstChildElement_fromArray() {
        let child = TestNode(element: .item,
                             attributes: [:],
                             children: [])
        let node = TestNode(element: .root,
                            attributes: [:],
                            children: [child])

        #expect(node.firstChildElement([.child, .item]) != nil)
    }

    @Test
    func firstChildElement_notFound() {
        let child = TestNode(element: .child,
                             attributes: [:],
                             children: [])
        let node = TestNode(element: .root,
                            attributes: [:],
                            children: [child])

        #expect(node.firstChildElement(.item) == nil)
    }

    @Test
    func firstChildElement_textNode() {
        let node = TestNode(text: "text")

        #expect(node.firstChildElement(.child) == nil)
    }

    @Test
    func init_elementDefaultAttributesAndChildren() {
        let node = TestNode(element: .root)

        #expect(node.isElement)
        #expect(node.attributes?.isEmpty == true)
        #expect(node.children?.isEmpty == true)
    }

    @Test
    func init_elementDefaultChildren() {
        let node = TestNode(element: .root,
                            attributes: [.name: "value"])

        #expect(node.attributes == [.name: "value"])
        #expect(node.children?.isEmpty == true)
    }

    @Test
    func isElement_elementNode() {
        let node = TestNode(element: .root,
                            attributes: [:],
                            children: [])

        #expect(node.isElement)
    }

    @Test
    func isElement_fromArray() {
        let node = TestNode(element: .root,
                            attributes: [:],
                            children: [])

        #expect(node.isElement([.root, .child]))
    }

    @Test
    func isElement_matching() {
        let node = TestNode(element: .root,
                            attributes: [:],
                            children: [])

        #expect(node.isElement(.root))
    }

    @Test
    func isElement_notMatching() {
        let node = TestNode(element: .root,
                            attributes: [:],
                            children: [])

        #expect(!node.isElement(.child))
    }

    @Test
    func isElement_textNode() {
        let node = TestNode(text: "text")

        #expect(!node.isElement(.root))
    }

    @Test
    func isElement_textNodeIsFalse() {
        let node = TestNode(text: "hello")

        #expect(!node.isElement)
    }

    @Test
    func isText_elementNode() {
        let node = TestNode(element: .root,
                            attributes: [:],
                            children: [])

        #expect(!node.isText)
    }

    @Test
    func isText_textNode() {
        let node = TestNode(text: "hello")

        #expect(node.isText)
    }

    @Test
    func name_elementNode() {
        let node = TestNode(element: .root,
                            attributes: [:],
                            children: [])

        #expect(node.name == "root")
    }

    @Test
    func name_textNode() {
        let node = TestNode(text: "hello")

        #expect(node.name == nil)
    }

    @Test
    func processingInstruction_accessors() {
        let node = TestNode(processingInstruction: "pi",
                            data: "a=\"1\"")

        #expect(node.isProcessingInstruction)
        #expect(node.target == "pi")
        #expect(node.data == "a=\"1\"")
        #expect(!node.isComment)
        #expect(!node.isElement)
        #expect(!node.isText)
        #expect(node.comment == nil)
    }

    @Test
    func processingInstruction_description() {
        #expect(TestNode(processingInstruction: "pi", data: "d").description == "<?pi d?>")
        #expect(TestNode(processingInstruction: "pi").description == "<?pi?>")
    }

    @Test
    func processingInstruction_hasNilValue() {
        #expect(TestNode(processingInstruction: "pi", data: "d").value == nil)
    }

    @Test
    func processingInstruction_withoutDataHasNilData() {
        #expect(TestNode(processingInstruction: "pi").data == nil)
    }

    @Test
    func uri_elementNode() {
        let node = TestNode(element: .root,
                            attributes: [:],
                            children: [])

        #expect(node.uri == nil)
    }

    @Test
    func uri_textNode() {
        let node = TestNode(text: "hello")

        #expect(node.uri == nil)
    }

    @Test
    func value_elementNodeNestedElements() {
        let innerText = TestNode(text: "inner")
        let inner = TestNode(element: .child,
                             attributes: [:],
                             children: [innerText])
        let outerText = TestNode(text: "outer")
        let node = TestNode(element: .root,
                            attributes: [:],
                            children: [outerText, inner])

        #expect(node.value == "outerinner")
    }

    @Test
    func value_elementNodeNoChildren() {
        let node = TestNode(element: .root,
                            attributes: [:],
                            children: [])

        //  An element node always has a value, even with nothing to contribute
        //  one; only a comment or processing instruction has none at all.
        #expect(node.value?.isEmpty == true)
    }

    @Test
    func value_elementNodeTextChildren() {
        let text1 = TestNode(text: "hello ")
        let text2 = TestNode(text: "world")
        let node = TestNode(element: .root,
                            attributes: [:],
                            children: [text1, text2])

        #expect(node.value == "hello world")
    }

    @Test
    func value_textNode() {
        let node = TestNode(text: "hello")

        #expect(node.value == "hello")
    }
}
