// © 2026 John Gary Pusey (see LICENSE.md)

internal import CoreFoundation
internal import Foundation

extension String.Encoding {

    // MARK: Internal Initializers

    //
    // Resolves the name of a character encoding, as it appears in the `encoding`
    // pseudo-attribute of an XML declaration, to the encoding itself.
    //
    // The names are the IANA charset names that the XML specification calls for,
    // and the mapping is Core Foundation's, so the aliases and the case folding
    // are exactly the ones every other reader of these documents applies.
    //
    internal init?(xmlName: String) {
        let encoding = CFStringConvertIANACharSetNameToEncoding(xmlName as CFString)

        guard encoding != kCFStringEncodingInvalidId
        else { return nil }

        self.init(rawValue: CFStringConvertEncodingToNSStringEncoding(encoding))

        //
        // Being able to write an encoding is of no use if nothing can read it
        // back. The XML specification obliges a parser to support UTF-8 and
        // UTF-16 and nothing else, and UTF-32 is where that bites: a UTF-32
        // document opens with a byte order mark whose first two bytes are
        // themselves a UTF-16 byte order mark, so a parser reasonably takes it
        // for UTF-16 and reads a document of nulls. That the big-endian variant
        // happens to survive, being detectable from its first four bytes, is an
        // accident of byte order rather than a distinction worth drawing in an
        // API, so the whole family is refused together.
        //
        guard !unreadableEncodings.contains(self)
        else { return nil }
    }
}

// MARK: - Private Constants

private let unreadableEncodings: Set<String.Encoding> = [.utf32,
                                                         .utf32BigEndian,
                                                         .utf32LittleEndian]
