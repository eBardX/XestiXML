// © 2026 John Gary Pusey (see LICENSE.md)

import Testing
import XestiTools
@testable import XestiXML

struct XMLErrorTests {
}

// MARK: -

extension XMLErrorTests {
    @Test
    func test_cause_nonParseFailure() {
        let error = XMLError.internalFailure

        #expect(error.cause == nil)
    }

    @Test
    func test_cause_parseFailureWithError() {
        let cause = XMLError.internalFailure
        let error = XMLError.parseFailure(cause, 1, 1)

        #expect(error.cause != nil)
    }

    @Test
    func test_cause_parseFailureWithoutError() {
        let error = XMLError.parseFailure(nil, 1, 1)

        #expect(error.cause == nil)
    }

    @Test
    func test_message_formatListEmptyNames() {
        let error = XMLError.invalidAttributeValue([], "val")

        #expect(error.message.contains("(unknown)"))
    }

    @Test
    func test_message_formatListThreeNames() {
        let error = XMLError.invalidAttributeValue(["a", "b", "c"], "val")

        #expect(error.message.contains("a, b, or c"))
    }

    @Test
    func test_message_formatListTwoNames() {
        let error = XMLError.invalidAttributeValue(["a", "b"], "val")

        #expect(error.message.contains("a or b"))
    }

    @Test
    func test_message_internalFailure() {
        let error = XMLError.internalFailure

        #expect(error.message == "Internal failure")
    }

    @Test
    func test_message_invalidAttributeValue() {
        let error = XMLError.invalidAttributeValue(["attr1"], "bad")

        #expect(error.message.contains("attr1"))
        #expect(error.message.contains("bad"))
    }

    @Test
    func test_message_invalidElementValue() {
        let error = XMLError.invalidElementValue(["elem"], "bad")

        #expect(error.message.contains("<elem>"))
        #expect(error.message.contains("bad"))
    }

    @Test
    func test_message_missingRequiredAttribute() {
        let error = XMLError.missingRequiredAttribute("parent", ["attr"])

        #expect(error.message.contains("attr"))
        #expect(error.message.contains("<parent>"))
    }

    @Test
    func test_message_missingRequiredChildElement() {
        let error = XMLError.missingRequiredChildElement("parent", ["child"])

        #expect(error.message.contains("<child>"))
        #expect(error.message.contains("<parent>"))
    }

    @Test
    func test_message_parseFailure() {
        let error = XMLError.parseFailure(nil, 5, 10)

        #expect(error.message.contains("5"))
        #expect(error.message.contains("10"))
    }

    @Test
    func test_message_unexpectedElement() {
        let error = XMLError.unexpectedElement("actual", ["expected1", "expected2"])

        #expect(error.message.contains("<actual>"))
        #expect(error.message.contains("<expected1>"))
        #expect(error.message.contains("<expected2>"))
    }

    @Test
    func test_message_unexpectedRootElement() {
        let error = XMLError.unexpectedRootElement("root")

        #expect(error.message.contains("<root>"))
    }

    @Test
    func test_message_unrecognizedAttribute() {
        let error = XMLError.unrecognizedAttribute("attr", 3, 7)

        #expect(error.message.contains("attr"))
        #expect(error.message.contains("3"))
        #expect(error.message.contains("7"))
    }

    @Test
    func test_message_unrecognizedElementWithURI() {
        let error = XMLError.unrecognizedElement("elem", "http://example.com", 1, 2)

        #expect(error.message.contains("elem"))
        #expect(error.message.contains("http://example.com"))
    }

    @Test
    func test_message_unrecognizedElementWithoutURI() {
        let error = XMLError.unrecognizedElement("elem", nil, 1, 2)

        #expect(error.message.contains("elem"))
    }

    @Test
    func test_message_unsupportedRootElement() {
        let error = XMLError.unsupportedRootElement("root")

        #expect(error.message.contains("<root>"))
    }
}
