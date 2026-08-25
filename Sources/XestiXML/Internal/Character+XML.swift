// © 2022–2026 John Gary Pusey (see LICENSE.md)

extension Character {
    internal var isXMLWhitespace: Bool {
        //
        // According to the XML 1.0 specification, whitespace consists of one or
        // more space (#x20), carriage return (#xD), line feed (#xA), or tab
        // (#x9) characters.
        //
        switch self {
        case " ",
             "\n",
             "\r",
             "\t":
            true

        default:
            false
        }
    }
}
