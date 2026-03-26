// © 2026 John Gary Pusey (see LICENSE.md)

import Testing
@testable import XestiXML

struct CharacterXMLTests {
}

// MARK: -

extension CharacterXMLTests {
    @Test
    func test_carriageReturnIsXMLWhitespace() {
        #expect(Character("\r").isXMLWhitespace)
    }

    @Test
    func test_digitIsNotXMLWhitespace() {
        #expect(!Character("0").isXMLWhitespace)
    }

    @Test
    func test_letterIsNotXMLWhitespace() {
        #expect(!Character("A").isXMLWhitespace)
    }

    @Test
    func test_lineFeedIsXMLWhitespace() {
        #expect(Character("\n").isXMLWhitespace)
    }

    @Test
    func test_nonBreakingSpaceIsNotXMLWhitespace() {
        #expect(!Character("\u{00A0}").isXMLWhitespace)
    }

    @Test
    func test_punctuationIsNotXMLWhitespace() {
        #expect(!Character(".").isXMLWhitespace)
    }

    @Test
    func test_spaceIsXMLWhitespace() {
        #expect(Character(" ").isXMLWhitespace)
    }

    @Test
    func test_tabIsXMLWhitespace() {
        #expect(Character("\t").isXMLWhitespace)
    }

    @Test
    func test_unicodeCharacterIsNotXMLWhitespace() {
        #expect(!Character("é").isXMLWhitespace)
    }
}
