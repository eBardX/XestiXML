// © 2026 John Gary Pusey (see LICENSE.md)

import Testing
import XestiTools
@testable import XestiXML

struct XMLParserErrorTests {
}

// MARK: -

extension XMLParserErrorTests {
    @Test
    func cause_nonParseFailure() {
        let error = TestParser.Error.internalFailure

        #expect(error.cause == nil)
    }

    @Test
    func cause_parseFailureWithError() {
        let cause = TestParser.Error.internalFailure
        let error = TestParser.Error.parseFailure(cause, 1, 1)

        #expect(error.cause != nil)
    }

    @Test
    func cause_parseFailureWithoutError() {
        let error = TestParser.Error.parseFailure(nil, 1, 1)

        #expect(error.cause == nil)
    }

    @Test
    func message_internalFailure() {
        let error = TestParser.Error.internalFailure

        #expect(error.message == "Internal failure")
    }

    @Test
    func message_parseFailure() {
        let error = TestParser.Error.parseFailure(nil, 5, 10)

        #expect(error.message.contains("5"))
        #expect(error.message.contains("10"))
    }

    @Test
    func message_unrecognizedAttribute() {
        let error = TestParser.Error.unrecognizedAttribute("attr", 3, 7)

        #expect(error.message.contains("attr"))
        #expect(error.message.contains("3"))
        #expect(error.message.contains("7"))
    }

    @Test
    func message_unrecognizedElementWithoutURI() {
        let error = TestParser.Error.unrecognizedElement("elem", nil, 1, 2)

        #expect(error.message.contains("elem"))
    }

    @Test
    func message_unrecognizedElementWithURI() {
        let error = TestParser.Error.unrecognizedElement("elem", "http://example.com", 1, 2)

        #expect(error.message.contains("elem"))
        #expect(error.message.contains("http://example.com"))
    }
}
