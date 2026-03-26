// © 2026 John Gary Pusey (see LICENSE.md)

import Testing
@testable import XestiXML

private enum TestAttribute: String, XMLAttribute {
    case id
    case name
    case value
}

struct XMLAttributeTests {
}

// MARK: -

extension XMLAttributeTests {
    @Test
    func test_equalityDifferentValues() {
        let attr1 = TestAttribute.id
        let attr2 = TestAttribute.name

        #expect(attr1 != attr2)
    }

    @Test
    func test_equalitySameValues() {
        let attr1 = TestAttribute.id
        let attr2 = TestAttribute.id

        #expect(attr1 == attr2)
    }

    @Test
    func test_failableInitWithInvalidName() {
        let attr = TestAttribute(name: "nonexistent")

        #expect(attr == nil)
    }

    @Test
    func test_failableInitWithValidName() {
        let attr = TestAttribute(name: "id")

        #expect(attr != nil)
        #expect(attr?.name == "id")
    }

    @Test
    func test_hashable() {
        let attr1 = TestAttribute.id
        let attr2 = TestAttribute.id
        let attr3 = TestAttribute.name

        var set = Set<TestAttribute>()

        set.insert(attr1)
        set.insert(attr2)
        set.insert(attr3)

        #expect(set.count == 2)
    }

    @Test
    func test_initWithValidName() {
        let attr = TestAttribute("id")

        #expect(attr.name == "id")
    }

    @Test
    func test_nameProperty() {
        #expect(TestAttribute.id.name == "id")
        #expect(TestAttribute.name.name == "name")
        #expect(TestAttribute.value.name == "value")
    }
}
