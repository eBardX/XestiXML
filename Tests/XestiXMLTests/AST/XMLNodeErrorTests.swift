// © 2026 John Gary Pusey (see LICENSE.md)

import Testing
import XestiTools
@testable import XestiXML

struct XMLNodeErrorTests {
}

// MARK: -

extension XMLNodeErrorTests {
    @Test
    func message_formatListEmptyNames() {
        let error = TestNode.Error.invalidAttributeValue([], "val")

        #expect(error.message.contains("(unknown)"))
    }

    @Test
    func message_formatListThreeNames() {
        let error = TestNode.Error.invalidAttributeValue(["a", "b", "c"], "val")

        #expect(error.message.contains("a, b, or c"))
    }

    @Test
    func message_formatListTwoNames() {
        let error = TestNode.Error.invalidAttributeValue(["a", "b"], "val")

        #expect(error.message.contains("a or b"))
    }

    @Test
    func message_internalFailure() {
        let error = TestNode.Error.internalFailure

        #expect(error.message == "Internal failure")
    }

    @Test
    func message_invalidAttributeValue() {
        let error = TestNode.Error.invalidAttributeValue(["attr1"], "bad")

        #expect(error.message.contains("attr1"))
        #expect(error.message.contains("bad"))
    }

    @Test
    func message_invalidElementValue() {
        let error = TestNode.Error.invalidElementValue(["elem"], "bad")

        #expect(error.message.contains("<elem>"))
        #expect(error.message.contains("bad"))
    }

    @Test
    func message_missingRequiredAttribute() {
        let error = TestNode.Error.missingRequiredAttribute("parent", ["attr"])

        #expect(error.message.contains("attr"))
        #expect(error.message.contains("<parent>"))
    }

    @Test
    func message_missingRequiredChildElement() {
        let error = TestNode.Error.missingRequiredChildElement("parent", ["child"])

        #expect(error.message.contains("<child>"))
        #expect(error.message.contains("<parent>"))
    }

    @Test
    func message_unexpectedElement() {
        let error = TestNode.Error.unexpectedElement("actual", ["expected1", "expected2"])

        #expect(error.message.contains("<actual>"))
        #expect(error.message.contains("<expected1>"))
        #expect(error.message.contains("<expected2>"))
    }

    @Test
    func message_unexpectedRootElement() {
        let error = TestNode.Error.unexpectedRootElement("root")

        #expect(error.message.contains("<root>"))
    }

    @Test
    func message_unsupportedRootElement() {
        let error = TestNode.Error.unsupportedRootElement("root")

        #expect(error.message.contains("<root>"))
    }
}
