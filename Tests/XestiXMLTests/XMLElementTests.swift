// © 2026 John Gary Pusey (see LICENSE.md)

import Testing
import XestiTools
@testable import XestiXML

private enum TestElement: String, XMLElement {
    case child
    case item
    case root
}

private struct SRTestElement: XMLElement, StringRepresentable {
    let stringValue: String

    init?(stringValue: String) {
        guard Self.isValid(stringValue)
        else { return nil }

        self.stringValue = stringValue
    }
}

struct XMLElementTests {
}

// MARK: -

extension XMLElementTests {
    @Test
    func test_equalityDifferentValues() {
        let elem1 = TestElement.root
        let elem2 = TestElement.child

        #expect(elem1 != elem2)
    }

    @Test
    func test_equalitySameValues() {
        let elem1 = TestElement.root
        let elem2 = TestElement.root

        #expect(elem1 == elem2)
    }

    @Test
    func test_failableInitWithInvalidName() {
        let elem = TestElement(name: "nonexistent", uri: nil)

        #expect(elem == nil)
    }

    @Test
    func test_failableInitWithNonNilURI() {
        let elem = TestElement(name: "root", uri: "http://example.com")

        #expect(elem == nil)
    }

    @Test
    func test_failableInitWithValidName() {
        let elem = TestElement(name: "root", uri: nil)

        #expect(elem != nil)
        #expect(elem?.name == "root")
    }

    @Test
    func test_initWithValidNameAndNilURI() {
        let elem = TestElement("root", nil)

        #expect(elem.name == "root")
    }

    @Test
    func test_nameProperty() {
        #expect(TestElement.root.name == "root")
        #expect(TestElement.child.name == "child")
        #expect(TestElement.item.name == "item")
    }

    @Test
    func test_uriPropertyAlwaysNil() {
        #expect(TestElement.root.uri == nil)
        #expect(TestElement.child.uri == nil)
    }

    @Test
    func test_stringRepresentableFailableInitWithEmptyName() {
        let elem = SRTestElement(name: "", uri: nil)

        #expect(elem == nil)
    }

    @Test
    func test_stringRepresentableFailableInitWithNonNilURI() {
        let elem = SRTestElement(name: "root", uri: "http://example.com")

        #expect(elem == nil)
    }

    @Test
    func test_stringRepresentableFailableInitWithValidName() {
        let elem = SRTestElement(name: "root", uri: nil)

        #expect(elem != nil)
        #expect(elem?.name == "root")
    }

    @Test
    func test_stringRepresentableInitWithValidNameAndNilURI() {
        let elem = SRTestElement("root", nil)

        #expect(elem.name == "root")
    }

    @Test
    func test_stringRepresentableNameProperty() {
        let elem = SRTestElement("test", nil)

        #expect(elem.name == "test")
    }

    @Test
    func test_stringRepresentableURIAlwaysNil() {
        let elem = SRTestElement("root", nil)

        #expect(elem.uri == nil)
    }
}
