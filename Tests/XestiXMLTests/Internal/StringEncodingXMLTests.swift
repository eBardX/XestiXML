// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
import Testing
@testable import XestiXML

struct StringEncodingXMLTests {
}

// MARK: -

extension StringEncodingXMLTests {
    @Test
    func init_caseInsensitiveName() {
        #expect(String.Encoding(xmlName: "utf-8") == .utf8)
    }

    @Test
    func init_recognizedAlias() {
        #expect(String.Encoding(xmlName: "ISO-8859-1") == .isoLatin1)
    }

    @Test
    func init_unrecognizedName() {
        #expect(String.Encoding(xmlName: "bogus-charset") == nil)
    }

    @Test
    func init_utf32BigEndianIsRefused() {
        #expect(String.Encoding(xmlName: "UTF-32BE") == nil)
    }

    @Test
    func init_utf32IsRefused() {
        #expect(String.Encoding(xmlName: "UTF-32") == nil)
    }

    @Test
    func init_utf32LittleEndianIsRefused() {
        #expect(String.Encoding(xmlName: "UTF-32LE") == nil)
    }

    @Test
    func init_validName() {
        #expect(String.Encoding(xmlName: "UTF-8") == .utf8)
    }
}
