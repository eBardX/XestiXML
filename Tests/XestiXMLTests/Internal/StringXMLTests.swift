// © 2026 John Gary Pusey (see LICENSE.md)

import Testing
@testable import XestiXML

struct StringXMLTests {
}

// MARK: -

extension StringXMLTests {
    @Test
    func test_normalizedXMLWhitespace_collapsesTabs() {
        #expect("a\t\tb".normalizedXMLWhitespace() == "a b")
    }

    @Test
    func test_normalizedXMLWhitespace_collapsesWhitespace() {
        #expect("a   b".normalizedXMLWhitespace() == "a b")
    }

    @Test
    func test_normalizedXMLWhitespace_emptyString() {
        #expect("".normalizedXMLWhitespace().isEmpty)
    }

    @Test
    func test_normalizedXMLWhitespace_mixedWhitespace() {
        #expect("  hello \t world \n ".normalizedXMLWhitespace() == "hello world")
    }

    @Test
    func test_normalizedXMLWhitespace_noWhitespace() {
        #expect("hello".normalizedXMLWhitespace() == "hello")
    }

    @Test
    func test_normalizedXMLWhitespace_onlyWhitespace() {
        #expect("   ".normalizedXMLWhitespace().isEmpty)
    }

    @Test
    func test_normalizedXMLWhitespace_stripsLeading() {
        #expect("  hello".normalizedXMLWhitespace() == "hello")
    }

    @Test
    func test_normalizedXMLWhitespace_stripsTrailing() {
        #expect("hello  ".normalizedXMLWhitespace() == "hello")
    }

    @Test
    func test_normalizedXMLWhitespace_withCarriageReturns() {
        #expect("a\r\rb".normalizedXMLWhitespace() == "a b")
    }

    @Test
    func test_normalizedXMLWhitespace_withNewlines() {
        #expect("a\n\nb".normalizedXMLWhitespace() == "a b")
    }
}
