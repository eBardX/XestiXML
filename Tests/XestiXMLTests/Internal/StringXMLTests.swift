// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
import Testing
@testable import XestiXML

struct StringXMLTests {
}

// MARK: -

extension StringXMLTests {
    @Test
    func escapedXMLAttributeValue_escapesMarkup() {
        #expect("a<b>&c\"d".escapedXMLAttributeValue() == "a&lt;b&gt;&amp;c&quot;d")
    }

    //  A character the encoding cannot carry becomes a character reference, and
    //  one it can is left alone — in the same string, so that the choice is made
    //  per character rather than for the value as a whole.
    @Test
    func escapedXMLAttributeValue_escapesUnrepresentable() {
        #expect("café".escapedXMLAttributeValue(CharacterRepertoire(.ascii)) == "caf&#xe9;")
        #expect("café".escapedXMLAttributeValue(CharacterRepertoire(.isoLatin1)) == "café")
        #expect("a😀b".escapedXMLAttributeValue(CharacterRepertoire(.isoLatin1)) == "a&#x1f600;b")
    }

    @Test
    func escapedXMLAttributeValue_escapesWhitespace() {
        #expect("a\tb\nc\rd".escapedXMLAttributeValue() == "a&#x9;b&#xa;c&#xd;d")
    }

    @Test
    func escapedXMLAttributeValue_invalidCharacter() {
        #expect("a\u{1}b".escapedXMLAttributeValue() == nil)
    }

    @Test
    func escapedXMLText_emptyString() {
        #expect("".escapedXMLText()?.isEmpty == true)
    }

    @Test
    func escapedXMLText_escapesCarriageReturn() {
        #expect("a\rb".escapedXMLText() == "a&#xd;b")
    }

    @Test
    func escapedXMLText_escapesMarkup() {
        #expect("a<b>&c".escapedXMLText() == "a&lt;b&gt;&amp;c")
    }

    @Test
    func escapedXMLText_escapesUnrepresentable() {
        #expect("café".escapedXMLText(CharacterRepertoire(.ascii)) == "caf&#xe9;")
        #expect("café".escapedXMLText(CharacterRepertoire(.isoLatin1)) == "café")
    }

    @Test
    func escapedXMLText_invalidCharacter() {
        #expect("a\u{0}b".escapedXMLText() == nil)
    }

    @Test
    func escapedXMLText_preservesNonASCII() {
        #expect("héllo 😀".escapedXMLText() == "héllo 😀")
    }

    @Test
    func escapedXMLText_preservesQuotesAndWhitespace() {
        #expect("a\"b\tc\nd".escapedXMLText() == "a\"b\tc\nd")
    }

    @Test
    func isXMLName_emptyString() {
        #expect(!"".isXMLName)
    }

    @Test
    func isXMLName_leadingDigit() {
        #expect(!"2bad".isXMLName)
    }

    @Test
    func isXMLName_nonASCIIName() {
        #expect("élément".isXMLName)
    }

    @Test
    func isXMLName_qualifiedName() {
        #expect("foo:bar".isXMLName)
    }

    @Test
    func isXMLName_simpleName() {
        #expect("root".isXMLName)
    }

    @Test
    func isXMLName_withEmbeddedSpace() {
        #expect(!"not a name".isXMLName)
    }

    @Test
    func isXMLName_withPunctuation() {
        #expect("_a-b.c1".isXMLName)
    }

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
