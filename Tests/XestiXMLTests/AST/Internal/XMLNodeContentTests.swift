// © 2026 John Gary Pusey (see LICENSE.md)

import Testing
@testable import XestiXML

struct XMLNodeContentTests {
}

// MARK: -

extension XMLNodeContentTests {
    @Test
    func comment() {
        let content = TestNode.Content.comment("note")

        guard case let .comment(text) = content
        else {
            Issue.record("Expected .comment case")

            return
        }

        #expect(text == "note")
    }

    @Test
    func element() {
        let content = TestNode.Content.element(.root, [.id: "1"], [])

        guard case let .element(elem, attrs, children) = content
        else {
            Issue.record("Expected .element case")

            return
        }

        #expect(elem == .root)
        #expect(attrs == [.id: "1"])
        #expect(children.isEmpty)
    }

    @Test
    func processingInstruction_withData() {
        let content = TestNode.Content.processingInstruction("pi", "data")

        guard case let .processingInstruction(target, data) = content
        else {
            Issue.record("Expected .processingInstruction case")

            return
        }

        #expect(target == "pi")
        #expect(data == "data")
    }

    @Test
    func processingInstruction_withoutData() {
        let content = TestNode.Content.processingInstruction("pi", nil)

        guard case let .processingInstruction(_, data) = content
        else {
            Issue.record("Expected .processingInstruction case")

            return
        }

        #expect(data == nil)
    }

    @Test
    func text() {
        let content = TestNode.Content.text("hello")

        guard case let .text(value) = content
        else {
            Issue.record("Expected .text case")

            return
        }

        #expect(value == "hello")
    }
}
