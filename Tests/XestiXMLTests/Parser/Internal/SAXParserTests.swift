// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
import Testing
@testable import XestiXML

struct SAXParserTests {
}

// MARK: -

extension SAXParserTests {
    @Test
    func saxParse_malformedDocumentReturnsFalse() {
        let sink = MockSAXEventSink()

        #expect(!saxParse(Data("<root><child></root>".utf8), sink))
    }

    @Test
    func saxParse_reportsDeclarationWhenPresent() {
        let sink = MockSAXEventSink()

        _ = saxParse(Data("<?xml version=\"1.0\" encoding=\"UTF-8\"?><root/>".utf8), sink)

        #expect(sink.declarations.first?.encoding == "UTF-8")
    }

    @Test
    func saxParse_reportsNoDeclarationWhenAbsent() {
        let sink = MockSAXEventSink()

        _ = saxParse(Data("<root/>".utf8), sink)

        //  libxml2's four-way encoding of `standalone`: `-1` means the document
        //  carried no XML declaration at all.
        #expect(sink.declarations.first?.standalone == -1)
    }

    @Test
    func saxParse_sinkAbortStopsParsing() {
        let sink = MockSAXEventSink()

        sink.stubbedShouldAbort = true

        #expect(!saxParse(Data("<root><child/><child/></root>".utf8), sink))
        #expect(sink.startedElements.count == 1)
        #expect(sink.abortedAt != nil)
    }

    @Test
    func saxParse_wellFormedDocumentReturnsTrue() {
        let sink = MockSAXEventSink()

        #expect(saxParse(Data("<root/>".utf8), sink))
    }
}
