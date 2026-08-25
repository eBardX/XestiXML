// © 2026 John Gary Pusey (see LICENSE.md)

import Testing
@testable import XestiXML

struct XMLDocumentTypeTests {
}

// MARK: -

extension XMLDocumentTypeTests {
    @Test
    func equality_differentName() {
        #expect(XMLDocumentType(name: "root") != XMLDocumentType(name: "other"))
    }

    @Test
    func equality_differentPublicID() {
        let one = XMLDocumentType(name: "root",
                                  publicID: "-//X//DTD X//EN",
                                  systemID: "x.dtd")
        let other = XMLDocumentType(name: "root",
                                    publicID: "-//Y//DTD Y//EN",
                                    systemID: "x.dtd")

        #expect(one != other)
    }

    @Test
    func equality_differentSystemID() {
        let one = XMLDocumentType(name: "root",
                                  systemID: "x.dtd")
        let other = XMLDocumentType(name: "root",
                                    systemID: "y.dtd")

        #expect(one != other)
    }

    @Test
    func equality_sameValues() {
        let one = XMLDocumentType(name: "root",
                                  publicID: "-//X//DTD X//EN",
                                  systemID: "x.dtd")
        let other = XMLDocumentType(name: "root",
                                    publicID: "-//X//DTD X//EN",
                                    systemID: "x.dtd")

        #expect(one == other)
    }

    @Test
    func init_defaults() {
        let documentType = XMLDocumentType(name: "root")

        #expect(documentType.name == "root")
        #expect(documentType.publicID == nil)
        #expect(documentType.systemID == nil)
    }

    @Test
    func init_fullValues() {
        let documentType = XMLDocumentType(name: "score-partwise",
                                           publicID: "-//Recordare//DTD MusicXML 4.0 Partwise//EN",
                                           systemID: "http://www.musicxml.org/dtds/partwise.dtd")

        #expect(documentType.name == "score-partwise")
        #expect(documentType.publicID == "-//Recordare//DTD MusicXML 4.0 Partwise//EN")
        #expect(documentType.systemID == "http://www.musicxml.org/dtds/partwise.dtd")
    }

    @Test
    func init_systemIDOnly() {
        let documentType = XMLDocumentType(name: "root",
                                           systemID: "root.dtd")

        #expect(documentType.publicID == nil)
        #expect(documentType.systemID == "root.dtd")
    }
}
