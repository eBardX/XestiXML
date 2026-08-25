// © 2026 John Gary Pusey (see LICENSE.md)

import Testing
@testable import XestiXML

struct XMLParserOptionsTests {
}

// MARK: -

extension XMLParserOptionsTests {
    @Test
    func equality() {
        let allFalse = TestParser.Options(stripsComments: false,
                                          stripsProcessingInstructions: false)
        let commentsOnly = TestParser.Options(stripsComments: true,
                                              stripsProcessingInstructions: false)

        #expect(TestParser.Options() == allFalse)
        #expect(TestParser.Options(stripsComments: true) == commentsOnly)
    }

    @Test
    func inequality() {
        #expect(TestParser.Options(stripsComments: true) != TestParser.Options())
        #expect(TestParser.Options(stripsProcessingInstructions: true) != TestParser.Options())
    }

    @Test
    func init_defaultValues() {
        let options = TestParser.Options()

        #expect(!options.stripsComments)
        #expect(!options.stripsProcessingInstructions)
    }

    @Test
    func init_explicitValues() {
        let options = TestParser.Options(stripsComments: true,
                                         stripsProcessingInstructions: true)

        #expect(options.stripsComments)
        #expect(options.stripsProcessingInstructions)
    }
}
