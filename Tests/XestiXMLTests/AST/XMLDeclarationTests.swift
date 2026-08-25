// © 2026 John Gary Pusey (see LICENSE.md)

import Testing
@testable import XestiXML

struct XMLDeclarationTests {
}

// MARK: -

extension XMLDeclarationTests {
    @Test
    func equality_differentEncoding() {
        #expect(XMLDeclaration(encoding: "UTF-8") != XMLDeclaration(encoding: "UTF-16"))
    }

    @Test
    func equality_differentIsStandalone() {
        #expect(XMLDeclaration(isStandalone: true) != XMLDeclaration(isStandalone: false))
    }

    @Test
    func equality_differentVersion() {
        #expect(XMLDeclaration(version: "1.0") != XMLDeclaration(version: "1.1"))
    }

    //  Saying nothing about standalone is not the same as saying "no", so the
    //  two must not compare equal.
    @Test
    func equality_nilIsStandaloneDiffersFromFalse() {
        #expect(XMLDeclaration(isStandalone: nil) != XMLDeclaration(isStandalone: false))
    }

    @Test
    func equality_sameValues() {
        let one = XMLDeclaration(version: "1.0",
                                 encoding: "UTF-8",
                                 isStandalone: true)
        let other = XMLDeclaration(version: "1.0",
                                   encoding: "UTF-8",
                                   isStandalone: true)

        #expect(one == other)
    }

    @Test
    func init_defaults() {
        let declaration = XMLDeclaration()

        #expect(declaration.version == "1.0")
        #expect(declaration.encoding == nil)
        #expect(declaration.isStandalone == nil)
    }

    @Test
    func init_fullValues() {
        let declaration = XMLDeclaration(version: "1.1",
                                         encoding: "ISO-8859-1",
                                         isStandalone: false)

        #expect(declaration.version == "1.1")
        #expect(declaration.encoding == "ISO-8859-1")
        #expect(declaration.isStandalone == false)
    }
}
