// © 2022–2024 John Gary Pusey (see LICENSE.md)

extension String {
    //
    // A representation of the string with whitespace normalized by stripping
    // leading and trailing whitespace and replacing sequences of whitespace
    // characters by single space. If only whitespace exists, return empty
    // string.
    //
    public func normalizedXMLWhitespace() -> String {
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

        return String(outChars)
    }
}
