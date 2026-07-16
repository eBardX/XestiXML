// © 2026 John Gary Pusey (see LICENSE.md)

import Testing
@testable import XestiXML

struct StringXMLTests {
}

// MARK: -

extension StringXMLTests {
    @Test
    func normalizedXMLWhitespace_collapsesTabs() {
        #expect("a\t\tb".normalizedXMLWhitespace() == "a b")
    }

    @Test
    func normalizedXMLWhitespace_collapsesWhitespace() {
        #expect("a   b".normalizedXMLWhitespace() == "a b")
    }

    @Test
    func normalizedXMLWhitespace_emptyString() {
        #expect("".normalizedXMLWhitespace().isEmpty)
    }

    @Test
    func normalizedXMLWhitespace_mixedWhitespace() {
        #expect("  hello \t world \n ".normalizedXMLWhitespace() == "hello world")
    }

    @Test
    func normalizedXMLWhitespace_noWhitespace() {
        #expect("hello".normalizedXMLWhitespace() == "hello")
    }

    @Test
    func normalizedXMLWhitespace_onlyWhitespace() {
        #expect("   ".normalizedXMLWhitespace().isEmpty)
    }

    @Test
    func normalizedXMLWhitespace_stripsLeading() {
        #expect("  hello".normalizedXMLWhitespace() == "hello")
    }

    @Test
    func normalizedXMLWhitespace_stripsTrailing() {
        #expect("hello  ".normalizedXMLWhitespace() == "hello")
    }

    @Test
    func normalizedXMLWhitespace_withCarriageReturns() {
        #expect("a\r\rb".normalizedXMLWhitespace() == "a b")
    }

    @Test
    func normalizedXMLWhitespace_withNewlines() {
        #expect("a\n\nb".normalizedXMLWhitespace() == "a b")
    }
}
