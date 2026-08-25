// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
import Testing

//  Every formatter test asserts that its output is well-formed XML, which is
//  worth nothing unless the assertion can fail. These tests prove it can, for
//  each kind of defect the formatter is meant to make impossible.
struct WellFormednessTests {
}

// MARK: -

extension WellFormednessTests {
    @Test
    func expectWellFormed_doubleHyphenInComment() {
        expectNotWellFormed("<root><!-- a -- b --></root>")
    }

    @Test
    func expectWellFormed_duplicateAttribute() {
        expectNotWellFormed("<root id=\"a\" id=\"b\"/>")
    }

    @Test
    func expectWellFormed_mismatchedTags() {
        expectNotWellFormed("<root><child></other></root>")
    }

    @Test
    func expectWellFormed_undeclaredPrefix() {
        expectNotWellFormed("<root><ns1:child/></root>")
    }

    @Test
    func expectWellFormed_unescapedAmpersand() {
        expectNotWellFormed("<root>a & b</root>")
    }

    @Test
    func expectWellFormed_wellFormedDocument() {
        expectWellFormed(Data("<root a=\"1\"><child>text</child></root>".utf8),
                         #_sourceLocation)
    }
}
