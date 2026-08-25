// © 2026 John Gary Pusey (see LICENSE.md)

import Testing
import XestiTools
@testable import XestiXML

struct XMLElementTests {
}

// MARK: -

extension XMLElementTests {
    @Test
    func equality_differentValues() {
        let elem1 = TestElement.root
        let elem2 = TestElement.child

        #expect(elem1 != elem2)
    }

    @Test
    func equality_sameValues() {
        let elem1 = TestElement.root
        let elem2 = TestElement.root

        #expect(elem1 == elem2)
    }

    @Test
    func failableInit_invalidName() {
        let elem = TestElement(name: "nonexistent", uri: nil)

        #expect(elem == nil)
    }

    @Test
    func failableInit_nonNilURI() {
        let elem = TestElement(name: "root", uri: "http://example.com")

        #expect(elem == nil)
    }

    @Test
    func failableInit_validName() {
        let elem = TestElement(name: "root", uri: nil)

        #expect(elem != nil)
        #expect(elem?.name == "root")
    }

    @Test
    func init_validNameAndNilURI() {
        let elem = TestElement("root", nil)

        #expect(elem.name == "root")
    }

    @Test
    func name() {
        #expect(TestElement.root.name == "root")
        #expect(TestElement.child.name == "child")
        #expect(TestElement.item.name == "item")
    }

    @Test
    func stringRepresentableFailableInit_emptyName() {
        let elem = SRTestElement(name: "", uri: nil)

        #expect(elem == nil)
    }

    @Test
    func stringRepresentableFailableInit_nonNilURI() {
        let elem = SRTestElement(name: "root", uri: "http://example.com")

        #expect(elem == nil)
    }

    @Test
    func stringRepresentableFailableInit_validName() {
        let elem = SRTestElement(name: "root", uri: nil)

        #expect(elem != nil)
        #expect(elem?.name == "root")
    }

    @Test
    func stringRepresentableInit_validNameAndNilURI() {
        let elem = SRTestElement("root", nil)

        #expect(elem.name == "root")
    }

    @Test
    func stringRepresentableName() {
        let elem = SRTestElement("test", nil)

        #expect(elem.name == "test")
    }

    @Test
    func stringRepresentableURI_alwaysNil() {
        let elem = SRTestElement("root", nil)

        #expect(elem.uri == nil)
    }

    @Test
    func uri_alwaysNil() {
        #expect(TestElement.root.uri == nil)
        #expect(TestElement.child.uri == nil)
    }
}
