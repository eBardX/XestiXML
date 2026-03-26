// © 2026 John Gary Pusey (see LICENSE.md)

import Testing
@testable import XestiXML

private enum TestElement: String, XMLElement {
    case child
    case item
    case root
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
}
