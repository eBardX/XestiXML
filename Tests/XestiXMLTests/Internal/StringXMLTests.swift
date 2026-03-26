// © 2026 John Gary Pusey (see LICENSE.md)

import Testing
@testable import XestiXML

struct StringXMLTests {
}

// MARK: -

extension StringXMLTests {
    @Test
    func test_normalizedXMLWhitespaceCollapsesTabs() {
        #expect("a\t\tb".normalizedXMLWhitespace() == "a b")
    }

    @Test
    func test_normalizedXMLWhitespaceCollapsesWhitespace() {
        #expect("a   b".normalizedXMLWhitespace() == "a b")
    }

    @Test
    func test_normalizedXMLWhitespaceEmptyString() {
        #expect("".normalizedXMLWhitespace().isEmpty)
    }

    @Test
    func test_normalizedXMLWhitespaceMixedWhitespace() {
        #expect("  hello \t world \n ".normalizedXMLWhitespace() == "hello world")
    }

    @Test
    func test_normalizedXMLWhitespaceNoWhitespace() {
        #expect("hello".normalizedXMLWhitespace() == "hello")
    }

    @Test
    func test_normalizedXMLWhitespaceOnlyWhitespace() {
        #expect("   ".normalizedXMLWhitespace().isEmpty)
    }

    @Test
    func test_normalizedXMLWhitespaceStripsLeading() {
        #expect("  hello".normalizedXMLWhitespace() == "hello")
    }

    @Test
    func test_normalizedXMLWhitespaceStripsTrailing() {
        #expect("hello  ".normalizedXMLWhitespace() == "hello")
    }

    @Test
    func test_normalizedXMLWhitespaceWithCarriageReturns() {
        #expect("a\r\rb".normalizedXMLWhitespace() == "a b")
    }

    @Test
    func test_normalizedXMLWhitespaceWithNewlines() {
        #expect("a\n\nb".normalizedXMLWhitespace() == "a b")
    }
}
