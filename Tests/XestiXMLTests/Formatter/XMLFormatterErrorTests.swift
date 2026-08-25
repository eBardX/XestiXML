// © 2026 John Gary Pusey (see LICENSE.md)

import Testing
import XestiTools
@testable import XestiXML

struct XMLFormatterErrorTests {
}

// MARK: -

extension XMLFormatterErrorTests {
    @Test
    func cause_isAlwaysNil() {
        #expect(TestFormatter.Error.invalidElementName("2bad").cause == nil)
        #expect(TestFormatter.Error.unexpectedRootTextNode.cause == nil)
    }

    @Test
    func message_invalidAttributeName() {
        let error = TestFormatter.Error.invalidAttributeName("not a name")

        #expect(error.message == "Invalid attribute name: not a name")
    }

    @Test
    func message_invalidAttributeValue() {
        let error = TestFormatter.Error.invalidAttributeValue("id", "bad")

        #expect(error.message == "Invalid value for id attribute: “bad”")
    }

    @Test
    func message_invalidElementName() {
        let error = TestFormatter.Error.invalidElementName("2bad")

        #expect(error.message == "Invalid element name: 2bad")
    }

    @Test
    func message_invalidTextValue() {
        let error = TestFormatter.Error.invalidTextValue("bad")

        #expect(error.message == "Invalid text value: “bad”")
    }

    @Test
    func message_reservedAttributeName() {
        let error = TestFormatter.Error.reservedAttributeName("xmlns")

        #expect(error.message == "Reserved attribute name: xmlns")
    }

    @Test
    func message_unexpectedRootTextNode() {
        let error = TestFormatter.Error.unexpectedRootTextNode

        #expect(error.message == "Unexpected text node as root of XML node tree")
    }

    @Test
    func message_unrepresentableContent() {
        let error = TestFormatter.Error.unrepresentableContent("café", "US-ASCII")

        #expect(error.message == "Cannot encode “café” in US-ASCII")
    }

    @Test
    func message_unsupportedEncoding() {
        let error = TestFormatter.Error.unsupportedEncoding("bogus")

        #expect(error.message == "Unsupported character encoding: bogus")
    }
}
