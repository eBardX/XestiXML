// © 2026 John Gary Pusey (see LICENSE.md)

import Testing
@testable import XestiXML

struct XMLFormatterOptionsTests {
}

// MARK: -

extension XMLFormatterOptionsTests {
    @Test
    func compact() {
        let options = TestFormatter.Options.compact

        #expect(options.indentation == nil)
        #expect(options.emitsXMLDeclaration)
    }

    @Test
    func equality() {
        #expect(TestFormatter.Options() == .compact)
        #expect(TestFormatter.Options(indentation: 4) == .pretty)
    }

    @Test
    func inequality() {
        #expect(TestFormatter.Options.compact != .pretty)
        #expect(TestFormatter.Options(emitsXMLDeclaration: false) != .compact)
    }

    @Test
    func init_defaultValues() {
        let options = TestFormatter.Options()

        #expect(options.indentation == nil)
        #expect(options.emitsXMLDeclaration)
    }

    @Test
    func init_explicitValues() {
        let options = TestFormatter.Options(emitsXMLDeclaration: false,
                                            indentation: 1)

        #expect(options.indentation == 1)
        #expect(!options.emitsXMLDeclaration)
    }

    @Test
    func pretty() {
        let options = TestFormatter.Options.pretty

        #expect(options.indentation == 4)
        #expect(options.emitsXMLDeclaration)
    }
}
