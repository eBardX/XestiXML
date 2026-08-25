// © 2026 John Gary Pusey (see LICENSE.md)

extension Unicode.Scalar {

    // MARK: Internal Instance Properties

    internal var isXMLCharacter: Bool {
        //
        // According to the XML 1.0 specification, a character is any Unicode
        // scalar value excluding the surrogate blocks, FFFE, and FFFF. Of the
        // C0 control characters, only tab (#x9), line feed (#xA), and carriage
        // return (#xD) are permitted.
        //
        switch value {
        case 0x09,
             0x0a,
             0x0d,
             0x20...0xd7ff,
             0xe000...0xfffd,
             0x10000...0x10ffff:
            true

        default:
            false
        }
    }

    internal var isXMLNameHead: Bool {
        //
        // According to the XML 1.0 specification, a name start character is a
        // letter, an underscore, or a colon (see the NameStartChar production).
        //
        switch value {
        case 0x3a,              // ':'
             0x41...0x5a,       // 'A'-'Z'
             0x5f,              // '_'
             0x61...0x7a,       // 'a'-'z'
             0xc0...0xd6,
             0xd8...0xf6,
             0xf8...0x02ff,
             0x0370...0x037d,
             0x037f...0x1fff,
             0x200c...0x200d,
             0x2070...0x218f,
             0x2c00...0x2fef,
             0x3001...0xd7ff,
             0xf900...0xfdcf,
             0xfdf0...0xfffd,
             0x10000...0xeffff:
            true

        default:
            false
        }
    }

    internal var isXMLNameTail: Bool {
        //
        // According to the XML 1.0 specification, a name character is a name
        // start character or one of a handful of additional characters (see the
        // NameChar production).
        //
        if isXMLNameHead {
            return true
        }

        switch value {
        case 0x2d,              // '-'
             0x2e,              // '.'
             0x30...0x39,       // '0'-'9'
             0xb7,
             0x0300...0x036f,
             0x203f...0x2040:
            return true

        default:
            return false
        }
    }

    internal var isXMLPublicIDCharacter: Bool {
        //
        // According to the XML 1.0 specification, a public identifier is built
        // from a restricted, entirely ASCII repertoire (see the PubidChar
        // production). Note that the apostrophe is included, even though it
        // cannot appear in a single-quoted public identifier literal.
        //
        switch value {
        case 0x0a,
             0x0d,
             0x20,
             0x21,          // !
             0x23...0x25,   // # $ %
             0x27...0x2f,   // ' ( ) * + , - . /
             0x30...0x39,   // 0-9
             0x3a,          // :
             0x3b,          // ;
             0x3d,          // =
             0x3f...0x40,   // ? @
             0x41...0x5a,   // A-Z
             0x5f,          // _
             0x61...0x7a:   // a-z
            true

        default:
            false
        }
    }
}
