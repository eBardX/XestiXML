// © 2026 John Gary Pusey (see LICENSE.md)

import Testing
import XestiTools
@testable import XestiXML

struct XMLElementTests {
}

// MARK: -

extension XMLElementTests {
    @Test
    func test_equality_differentValues() {
        let elem1 = TestElement.root
        let elem2 = TestElement.child

        #expect(elem1 != elem2)
    }

    @Test
    func test_equality_sameValues() {
        let elem1 = TestElement.root
        let elem2 = TestElement.root

        #expect(elem1 == elem2)
    }

    @Test
    func test_failableInit_invalidName() {
        let elem = TestElement(name: "nonexistent", uri: nil)

        #expect(elem == nil)
    }

    @Test
    func test_failableInit_nonNilURI() {
        let elem = TestElement(name: "root", uri: "http://example.com")

        #expect(elem == nil)
    }

    @Test
    func test_failableInit_validName() {
        let elem = TestElement(name: "root", uri: nil)

        #expect(elem != nil)
        #expect(elem?.name == "root")
    }

    @Test
    func test_init_validNameAndNilURI() {
        let elem = TestElement("root", nil)

        #expect(elem.name == "root")
    }

    @Test
    func test_name() {
        #expect(TestElement.root.name == "root")
        #expect(TestElement.child.name == "child")
        #expect(TestElement.item.name == "item")
    }

    @Test
    func test_stringRepresentableFailableInit_emptyName() {
        let elem = SRTestElement(name: "", uri: nil)

        #expect(elem == nil)
    }

    @Test
    func test_stringRepresentableFailableInit_nonNilURI() {
        let elem = SRTestElement(name: "root", uri: "http://example.com")

        #expect(elem == nil)
    }

    @Test
    func test_stringRepresentableFailableInit_validName() {
        let elem = SRTestElement(name: "root", uri: nil)

        #expect(elem != nil)
        #expect(elem?.name == "root")
    }

    @Test
    func test_stringRepresentableInit_validNameAndNilURI() {
        let elem = SRTestElement("root", nil)

        #expect(elem.name == "root")
    }

    @Test
    func test_stringRepresentableName() {
        let elem = SRTestElement("test", nil)

        #expect(elem.name == "test")
    }

    @Test
    func test_stringRepresentableURI_alwaysNil() {
        let elem = SRTestElement("root", nil)

        #expect(elem.uri == nil)
    }

    @Test
    func test_uri_alwaysNil() {
        #expect(TestElement.root.uri == nil)
        #expect(TestElement.child.uri == nil)
    }
}
