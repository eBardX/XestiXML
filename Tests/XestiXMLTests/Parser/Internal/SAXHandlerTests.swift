// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
import Testing
@testable import XestiXML

struct SAXHandlerTests {
}

// MARK: -

extension SAXHandlerTests {
    @Test
    func saxCdataBlock_callsAppendText() {
        let sink = MockSAXEventSink()

        _ = saxParse(Data("<root><![CDATA[hi]]></root>".utf8), sink)

        #expect(sink.texts == ["hi"])
    }

    @Test
    func saxCharacters_callsAppendText() {
        let sink = MockSAXEventSink()

        _ = saxParse(Data("<root>hi</root>".utf8), sink)

        #expect(sink.texts == ["hi"])
    }

    @Test
    func saxComment_callsAppendComment() {
        let sink = MockSAXEventSink()

        _ = saxParse(Data("<root><!-- note --></root>".utf8), sink)

        #expect(sink.comments == [" note "])
    }

    @Test
    func saxEndElementNs_reportsLocalNameAndURI() {
        let sink = MockSAXEventSink()

        _ = saxParse(Data("<root xmlns=\"urn:a\"><child/></root>".utf8), sink)

        #expect(sink.endedElements.map(\.name) == ["child", "root"])
        #expect(sink.endedElements.allSatisfy { $0.uri == "urn:a" })
    }

    @Test
    func saxError_callsHandleErrorWithStructuredError() {
        let sink = MockSAXEventSink()

        _ = saxParse(Data("<root><child></root>".utf8), sink)

        #expect(!sink.errors.isEmpty)
    }

    @Test
    func saxExternalSubset_endsInternalSubset_bareDoctype() {
        let sink = MockSAXEventSink()

        _ = saxParse(Data("<!DOCTYPE root><root/>".utf8), sink)

        #expect(sink.didEndInternalSubset)
    }

    @Test
    func saxExternalSubset_endsInternalSubset_emptySubset() {
        let sink = MockSAXEventSink()

        _ = saxParse(Data("<!DOCTYPE root []><root/>".utf8), sink)

        #expect(sink.didEndInternalSubset)
    }

    @Test
    func saxExternalSubset_endsInternalSubset_externalIdentifier() {
        let sink = MockSAXEventSink()

        _ = saxParse(Data("<!DOCTYPE root SYSTEM \"root.dtd\"><root/>".utf8), sink)

        #expect(sink.didEndInternalSubset)
    }

    @Test
    func saxExternalSubset_endsInternalSubset_populatedSubset() {
        let sink = MockSAXEventSink()

        _ = saxParse(Data("<!DOCTYPE root [<!ENTITY x \"y\">]><root/>".utf8), sink)

        #expect(sink.didEndInternalSubset)
    }

    @Test
    func saxInternalSubset_reportsHeader() {
        let sink = MockSAXEventSink()

        _ = saxParse(Data("<!DOCTYPE root SYSTEM \"root.dtd\"><root/>".utf8), sink)

        #expect(sink.documentTypes.first?.name == "root")
        #expect(sink.documentTypes.first?.systemID == "root.dtd")
    }

    @Test
    func saxProcessingInstruction_callsAppendProcessingInstruction() {
        let sink = MockSAXEventSink()

        _ = saxParse(Data("<root><?pi data?></root>".utf8), sink)

        #expect(sink.processingInstructions.first?.target == "pi")
        #expect(sink.processingInstructions.first?.data == "data")
    }

    @Test
    func saxStartElementNs_ampersandEntityInAttributeValueIsUnescaped() {
        let sink = MockSAXEventSink()

        _ = saxParse(Data("<root name=\"a&amp;b\"/>".utf8), sink)

        #expect(sink.startedElements.first?.attributes.first?.value == "a&b")
    }

    @Test
    func saxStartElementNs_attributePrefixIsDropped() {
        let sink = MockSAXEventSink()

        _ = saxParse(Data("<root xmlns:a=\"urn:a\" a:id=\"1\"/>".utf8), sink)

        let attribute = sink.startedElements.first?.attributes.first

        #expect(sink.startedElements.first?.attributes.count == 1)
        #expect(attribute?.name == "id")
        #expect(attribute?.uri == "urn:a")
    }

    @Test
    func saxStartElementNs_distinctNamespacedAttributesWithSameLocalName() {
        let sink = MockSAXEventSink()

        _ = saxParse(Data("<root xmlns:a=\"urn:a\" a:id=\"1\" id=\"2\"/>".utf8), sink)

        #expect(sink.startedElements.first?.attributes.count == 2)
    }

    @Test
    func saxStartElementNs_numericAmpersandReferenceInAttributeValueIsUnescaped() {
        let sink = MockSAXEventSink()

        _ = saxParse(Data("<root name=\"a&#38;b\"/>".utf8), sink)

        #expect(sink.startedElements.first?.attributes.first?.value == "a&b")
    }

    @Test
    func saxStartElementNs_reportsLocalNameAndURI() {
        let sink = MockSAXEventSink()

        _ = saxParse(Data("<root xmlns=\"urn:a\"/>".utf8), sink)

        #expect(sink.startedElements.first?.name == "root")
        #expect(sink.startedElements.first?.uri == "urn:a")
    }
}
