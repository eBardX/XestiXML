// © 2026 John Gary Pusey (see LICENSE.md)

import Testing
@testable import XestiXML

struct SAXAttributeTests {
}

// MARK: -

extension SAXAttributeTests {
    @Test
    func init_withoutURI() {
        let attribute = SAXAttribute("id", nil, "1")

        #expect(attribute.name == "id")
        #expect(attribute.uri == nil)
        #expect(attribute.value == "1")
    }

    @Test
    func init_withURI() {
        let attribute = SAXAttribute("id", "urn:a", "1")

        #expect(attribute.name == "id")
        #expect(attribute.uri == "urn:a")
        #expect(attribute.value == "1")
    }
}
