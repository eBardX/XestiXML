// © 2026 John Gary Pusey (see LICENSE.md)

import libxml2
import Testing
@testable import XestiXML

struct LibXMLErrorTests {
}

// MARK: -

extension LibXMLErrorTests {
    @Test
    func init_capturesFields() {
        "boom".withCString { messagePtr in
            var xmlErr = xmlError()

            xmlErr.code = 77
            xmlErr.int2 = 5
            xmlErr.level = XML_ERR_ERROR
            xmlErr.line = 3
            xmlErr.message = UnsafeMutablePointer(mutating: messagePtr)

            let error = LibXMLError(xmlErr)

            #expect(error.code == 77)
            #expect(error.column == 5)
            #expect(error.level == XML_ERR_ERROR.rawValue)
            #expect(error.line == 3)
            #expect(error.text == "boom")
        }
    }

    @Test
    func init_nilMessageBecomesEmptyText() {
        let error = LibXMLError(xmlError())

        #expect(error.text.isEmpty)
    }

    @Test
    func init_trimsWhitespaceFromMessage() {
        "  boom  \n".withCString { messagePtr in
            var xmlErr = xmlError()

            xmlErr.message = UnsafeMutablePointer(mutating: messagePtr)

            #expect(LibXMLError(xmlErr).text == "boom")
        }
    }

    @Test
    func isFailure_error() {
        var xmlErr = xmlError()

        xmlErr.level = XML_ERR_ERROR

        #expect(LibXMLError(xmlErr).isFailure)
    }

    @Test
    func isFailure_fatal() {
        var xmlErr = xmlError()

        xmlErr.level = XML_ERR_FATAL

        #expect(LibXMLError(xmlErr).isFailure)
    }

    @Test
    func isFailure_warning() {
        var xmlErr = xmlError()

        xmlErr.level = XML_ERR_WARNING

        #expect(!LibXMLError(xmlErr).isFailure)
    }

    @Test
    func message() {
        "boom".withCString { messagePtr in
            var xmlErr = xmlError()

            xmlErr.code = 5
            xmlErr.message = UnsafeMutablePointer(mutating: messagePtr)

            #expect(LibXMLError(xmlErr).message == "libxml2 error 5: boom")
        }
    }
}
