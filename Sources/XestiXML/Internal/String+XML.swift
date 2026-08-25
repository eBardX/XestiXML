// © 2022–2026 John Gary Pusey (see LICENSE.md)

extension String {

    // MARK: Internal Instance Properties

    internal var isXMLCharacters: Bool {
        unicodeScalars.allSatisfy { $0.isXMLCharacter }
    }

    internal var isXMLCommentValue: Bool {
        //
        // According to the XML 1.0 specification, the text of a comment must
        // not contain a double hyphen, and must not end with a hyphen (which
        // would produce one against the closing delimiter). There is no
        // escaping mechanism, so an offending comment simply cannot be written.
        //
        !contains("--")
            && !hasSuffix("-")
            && isXMLCharacters
    }

    internal var isXMLName: Bool {
        //
        // According to the XML 1.0 specification, a name begins with a name
        // start character followed by zero or more name characters.
        //
        guard let scalar = unicodeScalars.first,
              scalar.isXMLNameHead
        else { return false }

        return unicodeScalars.dropFirst().allSatisfy { $0.isXMLNameTail }
    }

    internal var isXMLNCName: Bool {
        //
        // According to the Namespaces in XML specification, an NCName is a name
        // with no colon in it. A namespace prefix is an NCName, since the colon
        // is what separates it from the local name it qualifies.
        //
        isXMLName
            && !contains(":")
    }

    internal var isXMLProcessingInstructionData: Bool {
        //
        // The data of a processing instruction runs to the first `?>`, so it
        // must not contain one. There is no escaping mechanism.
        //
        !contains("?>")
            && isXMLCharacters
    }

    internal var isXMLProcessingInstructionTarget: Bool {
        //
        // According to the XML 1.0 specification, a target is a name, and the
        // name `xml` is reserved in every combination of case.
        //
        isXMLName
            && lowercased() != "xml"
    }

    internal var isXMLPublicID: Bool {
        unicodeScalars.allSatisfy { $0.isXMLPublicIDCharacter }
    }

    internal var isXMLSystemID: Bool {
        //
        // A system identifier is written as a quoted literal and offers no
        // escaping, so it can be written only if one of the two quote
        // characters is absent from it.
        //
        (!contains("\"") || !contains("'"))
            && isXMLCharacters
    }

    internal var isXMLVersion: Bool {
        //
        // According to the XML 1.0 specification, a version number is `1.`
        // followed by at least one digit (see the VersionNum production).
        //
        hasPrefix("1.")
            && !dropFirst(2).isEmpty
            && dropFirst(2).allSatisfy { $0.isASCII && $0.isNumber }
    }

    // MARK: Internal Instance Methods

    internal func escapedXMLAttributeValue(_ repertoire: CharacterRepertoire = .universal()) -> String? {
        //
        // A representation of the string suitable for use as an attribute value
        // within a double-quoted attribute, or nil if the string contains a
        // character that cannot be represented in an XML document.
        //
        _escapedXML(inAttributeValue: true,
                    repertoire)
    }

    internal func escapedXMLText(_ repertoire: CharacterRepertoire = .universal()) -> String? {
        //
        // A representation of the string suitable for use as character data, or
        // nil if the string contains a character that cannot be represented in
        // an XML document.
        //
        _escapedXML(inAttributeValue: false,
                    repertoire)
    }

    internal func normalizedXMLWhitespace() -> String {
        //
        // A representation of the string with whitespace normalized by
        // stripping leading and trailing whitespace and replacing sequences of
        // whitespace characters by single space. If only whitespace exists,
        // return empty string.
        //
        guard !isEmpty
        else { return "" }

        var outChars: [Character] = []
        var whitespace = true

        for inChar in self {
            if !inChar.isXMLWhitespace {
                outChars.append(inChar)

                whitespace = false
            } else if !whitespace {
                outChars.append(" ")

                whitespace = true
            }
        }

        if whitespace {
            outChars = outChars.dropLast()
        }

        return String(outChars)
    }

    // MARK: Private Instance Methods

    private func _escapedXML(inAttributeValue: Bool,
                             _ repertoire: CharacterRepertoire) -> String? {
        var outScalars = String.UnicodeScalarView()

        outScalars.reserveCapacity(unicodeScalars.count)

        for inScalar in unicodeScalars {
            guard inScalar.isXMLCharacter
            else { return nil }

            switch inScalar {
            case "\n",
                 "\t":
                //
                // Attribute-value normalization would otherwise turn these into
                // spaces.
                //
                if inAttributeValue {
                    outScalars.append(contentsOf: "&#x\(String(inScalar.value, radix: 16));".unicodeScalars)
                } else {
                    outScalars.append(inScalar)
                }

            case "\r":
                //
                // End-of-line handling would otherwise turn this into a line
                // feed.
                //
                outScalars.append(contentsOf: "&#xd;".unicodeScalars)

            case "\"":
                if inAttributeValue {
                    outScalars.append(contentsOf: "&quot;".unicodeScalars)
                } else {
                    outScalars.append(inScalar)
                }

            case "&":
                outScalars.append(contentsOf: "&amp;".unicodeScalars)

            case "<":
                outScalars.append(contentsOf: "&lt;".unicodeScalars)

            case ">":
                outScalars.append(contentsOf: "&gt;".unicodeScalars)

            default:
                //
                // A character the encoding cannot carry is written as a numeric
                // character reference, which is made of characters every
                // encoding can. This is available here and nowhere else: a
                // reference is markup, and means nothing inside a name, a
                // comment, or a processing instruction.
                //
                if repertoire.canRepresent(inScalar) {
                    outScalars.append(inScalar)
                } else {
                    outScalars.append(contentsOf: "&#x\(String(inScalar.value, radix: 16));".unicodeScalars)
                }
            }
        }

        return String(outScalars)
    }
}
