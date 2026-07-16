// © 2026 John Gary Pusey (see LICENSE.md)

import Testing
@testable import XestiXML

struct CharacterXMLTests {
}

// MARK: -

extension CharacterXMLTests {
    @Test
    func isXMLWhitespace_carriageReturn() {
        #expect(Character("\r").isXMLWhitespace)
    }

    @Test
    func isXMLWhitespace_digit() {
        #expect(!Character("0").isXMLWhitespace)
    }

    @Test
    func isXMLWhitespace_letter() {
        #expect(!Character("A").isXMLWhitespace)
    }

    @Test
    func isXMLWhitespace_lineFeed() {
        #expect(Character("\n").isXMLWhitespace)
    }

    @Test
    func isXMLWhitespace_nonBreakingSpace() {
        #expect(!Character("\u{00A0}").isXMLWhitespace)
    }

    @Test
    func isXMLWhitespace_punctuation() {
        #expect(!Character(".").isXMLWhitespace)
    }

    @Test
    func isXMLWhitespace_space() {
        #expect(Character(" ").isXMLWhitespace)
    }

    @Test
    func isXMLWhitespace_tab() {
        #expect(Character("\t").isXMLWhitespace)
    }

    @Test
    func isXMLWhitespace_unicodeCharacter() {
        #expect(!Character("é").isXMLWhitespace)
    }
}
