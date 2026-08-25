// © 2026 John Gary Pusey (see LICENSE.md)

import Testing
@testable import XestiXML

struct UnicodeScalarXMLTests {
}

// MARK: -

extension UnicodeScalarXMLTests {
    @Test
    func isXMLCharacter_control() {
        #expect(!("\u{0}" as Unicode.Scalar).isXMLCharacter)
        #expect(!("\u{b}" as Unicode.Scalar).isXMLCharacter)
        #expect(!("\u{1f}" as Unicode.Scalar).isXMLCharacter)
    }

    @Test
    func isXMLCharacter_noncharacter() {
        #expect(!("\u{fffe}" as Unicode.Scalar).isXMLCharacter)
        #expect(!("\u{ffff}" as Unicode.Scalar).isXMLCharacter)
    }

    @Test
    func isXMLCharacter_permittedWhitespace() {
        #expect(("\u{9}" as Unicode.Scalar).isXMLCharacter)
        #expect(("\u{a}" as Unicode.Scalar).isXMLCharacter)
        #expect(("\u{d}" as Unicode.Scalar).isXMLCharacter)
    }

    @Test
    func isXMLCharacter_printable() {
        #expect(("a" as Unicode.Scalar).isXMLCharacter)
        #expect(("é" as Unicode.Scalar).isXMLCharacter)
        #expect(("😀" as Unicode.Scalar).isXMLCharacter)
    }

    @Test
    func isXMLNameHead_invalid() {
        #expect(!("0" as Unicode.Scalar).isXMLNameHead)
        #expect(!("-" as Unicode.Scalar).isXMLNameHead)
        #expect(!("." as Unicode.Scalar).isXMLNameHead)
        #expect(!(" " as Unicode.Scalar).isXMLNameHead)
    }

    @Test
    func isXMLNameHead_valid() {
        #expect(("A" as Unicode.Scalar).isXMLNameHead)
        #expect((":" as Unicode.Scalar).isXMLNameHead)
        #expect(("_" as Unicode.Scalar).isXMLNameHead)
        #expect(("z" as Unicode.Scalar).isXMLNameHead)
        #expect(("é" as Unicode.Scalar).isXMLNameHead)
    }

    @Test
    func isXMLNameTail_digitsAndPunctuation() {
        #expect(("0" as Unicode.Scalar).isXMLNameTail)
        #expect(("-" as Unicode.Scalar).isXMLNameTail)
        #expect(("." as Unicode.Scalar).isXMLNameTail)
        #expect(("a" as Unicode.Scalar).isXMLNameTail)
    }

    @Test
    func isXMLNameTail_invalid() {
        #expect(!(" " as Unicode.Scalar).isXMLNameTail)
        #expect(!("/" as Unicode.Scalar).isXMLNameTail)
    }
}
