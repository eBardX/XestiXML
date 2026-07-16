// © 2026 John Gary Pusey (see LICENSE.md)

import Testing
import XestiTools
@testable import XestiXML

struct XMLAttributeTests {
}

// MARK: -

extension XMLAttributeTests {
    @Test
    func equality_differentValues() {
        let attr1 = TestAttribute.id
        let attr2 = TestAttribute.name

        #expect(attr1 != attr2)
    }

    @Test
    func equality_sameValues() {
        let attr1 = TestAttribute.id
        let attr2 = TestAttribute.id

        #expect(attr1 == attr2)
    }

    @Test
    func failableInit_invalidName() {
        let attr = TestAttribute(name: "nonexistent")

        #expect(attr == nil)
    }

    @Test
    func failableInit_validName() {
        let attr = TestAttribute(name: "id")

        #expect(attr != nil)
        #expect(attr?.name == "id")
    }

    @Test
    func hashable() {
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
    func init_validName() {
        let attr = TestAttribute("id")

        #expect(attr.name == "id")
    }

    @Test
    func name() {
        #expect(TestAttribute.id.name == "id")
        #expect(TestAttribute.name.name == "name")
        #expect(TestAttribute.value.name == "value")
    }

    @Test
    func stringRepresentableFailableInit_emptyName() {
        let attr = SRTestAttribute(name: "")

        #expect(attr == nil)
    }

    @Test
    func stringRepresentableFailableInit_validName() {
        let attr = SRTestAttribute(name: "id")

        #expect(attr != nil)
        #expect(attr?.name == "id")
    }

    @Test
    func stringRepresentableInit_validName() {
        let attr = SRTestAttribute("id")

        #expect(attr.name == "id")
    }

    @Test
    func stringRepresentableName() {
        let attr = SRTestAttribute("test")

        #expect(attr.name == "test")
    }
}
