// © 2026 John Gary Pusey (see LICENSE.md)

import Testing
@testable import XestiXML

struct CharacterXMLTests {
}

// MARK: -

extension CharacterXMLTests {
    @Test
    func test_isXMLWhitespace_carriageReturn() {
        #expect(Character("\r").isXMLWhitespace)
    }

    @Test
    func test_isXMLWhitespace_digit() {
        #expect(!Character("0").isXMLWhitespace)
    }

    @Test
    func test_isXMLWhitespace_letter() {
        #expect(!Character("A").isXMLWhitespace)
    }

    @Test
    func test_isXMLWhitespace_lineFeed() {
        #expect(Character("\n").isXMLWhitespace)
    }

    @Test
    func test_isXMLWhitespace_nonBreakingSpace() {
        #expect(!Character("\u{00A0}").isXMLWhitespace)
    }

    @Test
    func test_isXMLWhitespace_punctuation() {
        #expect(!Character(".").isXMLWhitespace)
    }

    @Test
    func test_isXMLWhitespace_space() {
        #expect(Character(" ").isXMLWhitespace)
    }

    @Test
    func test_isXMLWhitespace_tab() {
        #expect(Character("\t").isXMLWhitespace)
    }

    @Test
    func test_isXMLWhitespace_unicodeCharacter() {
        #expect(!Character("é").isXMLWhitespace)
    }
}
