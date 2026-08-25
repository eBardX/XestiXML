// © 2026 John Gary Pusey (see LICENSE.md)

internal import Foundation

//  The characters that a character encoding is able to carry.
//
//  Only the encoding itself knows what it can represent, so each character is
//  answered for by trying it. The answers are remembered, because a document
//  asks about the same few hundred characters over and over, and a Unicode
//  encoding is not asked at all — it can carry everything, which is the common
//  case and deserves to cost nothing.
//
//  This is a reference type so that the cache may be filled from the escaping
//  routines, which have no business being mutating. An instance belongs to a
//  single call of `XMLFormatter.format(_:)` and is never shared between them.
internal final class CharacterRepertoire {

    // MARK: Internal Initializers

    internal init(_ encoding: String.Encoding) {
        self.encoding = encoding
        self.isUniversal = universalEncodings.contains(encoding)
    }

    // MARK: Private Instance Properties

    private let encoding: String.Encoding
    private let isUniversal: Bool

    private var answers: [Unicode.Scalar: Bool] = [:]
}

// MARK: -

extension CharacterRepertoire {

    // MARK: Internal Type Methods

    //  A repertoire that can carry every character there is, for the callers
    //  that are not encoding anything in particular.
    internal static func universal() -> CharacterRepertoire {
        CharacterRepertoire(.utf8)
    }

    // MARK: Internal Instance Methods

    internal func canRepresent(_ scalar: Unicode.Scalar) -> Bool {
        guard !isUniversal
        else { return true }

        if let answer = answers[scalar] {
            return answer
        }

        let answer = String(scalar).data(using: encoding) != nil

        answers[scalar] = answer

        return answer
    }

    //  The first character of the string that the encoding cannot carry, or nil
    //  if it can carry all of them.
    internal func firstUnrepresentable(in value: String) -> Unicode.Scalar? {
        guard !isUniversal
        else { return nil }

        return value.unicodeScalars.first { !canRepresent($0) }
    }
}

// MARK: - Private Constants

//
// The Unicode encodings can represent every character there is, so asking them
// one at a time would be a waste. UTF-32 is absent because it is refused before
// it ever reaches here.
//
private let universalEncodings: Set<String.Encoding> = [.utf8,
                                                        .utf16,
                                                        .utf16BigEndian,
                                                        .utf16LittleEndian]
