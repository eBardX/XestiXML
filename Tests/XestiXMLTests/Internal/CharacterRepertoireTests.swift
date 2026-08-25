// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
import Testing
@testable import XestiXML

struct CharacterRepertoireTests {
}

// MARK: -

extension CharacterRepertoireTests {
    @Test
    func canRepresent_isoLatin1() {
        let repertoire = CharacterRepertoire(.isoLatin1)

        #expect(repertoire.canRepresent("a"))
        #expect(repertoire.canRepresent("é"))
        #expect(!repertoire.canRepresent("😀"))
        #expect(!repertoire.canRepresent("\u{2014}"))
    }

    //  The second answer comes from the cache rather than the encoding, so it
    //  had better be the same as the first.
    @Test
    func canRepresent_repeatedQuestionsAgree() {
        let repertoire = CharacterRepertoire(.ascii)

        let firstAsked = [repertoire.canRepresent("a"),
                          repertoire.canRepresent("é")]

        let askedAgain = [repertoire.canRepresent("a"),
                          repertoire.canRepresent("é")]

        #expect(firstAsked == [true, false])
        #expect(askedAgain == firstAsked)
    }

    //  A Unicode encoding is never asked, since there is nothing it cannot
    //  carry.
    @Test
    func canRepresent_universal() {
        for encoding: String.Encoding in [.utf8, .utf16, .utf16BigEndian, .utf16LittleEndian] {
            let repertoire = CharacterRepertoire(encoding)

            #expect(repertoire.canRepresent("😀"))
            #expect(repertoire.canRepresent("\u{10ffff}"))
        }

        #expect(CharacterRepertoire.universal().canRepresent("😀"))
    }

    @Test
    func firstUnrepresentable_findsCharacter() {
        let repertoire = CharacterRepertoire(.ascii)

        #expect(repertoire.firstUnrepresentable(in: "café") == "é")
        #expect(repertoire.firstUnrepresentable(in: "naïve café") == "ï")
    }

    @Test
    func firstUnrepresentable_findsNothing() {
        #expect(CharacterRepertoire(.ascii).firstUnrepresentable(in: "plain") == nil)
        #expect(CharacterRepertoire(.isoLatin1).firstUnrepresentable(in: "café") == nil)
        #expect(CharacterRepertoire.universal().firstUnrepresentable(in: "café 😀") == nil)
    }
}
