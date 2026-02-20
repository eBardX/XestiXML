// © 2022–2026 John Gary Pusey (see LICENSE.md)

import Foundation

extension XMLParser {

    // MARK: Internal Nested Types

    internal final class Delegate: NSObject, XMLParserDelegate {

        internal typealias BaseXMLParser = Foundation.XMLParser

        // MARK: Internal Initializers

        override internal init() {
            self.context = Context()

            super.init()
        }

        // MARK: Internal Instance Properties

        internal private(set) var context: Context

        // MARK: Internal Instance Methods

        internal func parser(_ parser: BaseXMLParser,
                             didEndElement elementName: String,
                             namespaceURI: String?,
                             qualifiedName qName: String?) {
            context.endElement(elementName,
                               namespaceURI)
        }

        // internal func parser(_ parser: BaseXMLParser,
        //                      didEndMappingPrefix prefix: String) {
        // }

        internal func parser(_ parser: BaseXMLParser,
                             didStartElement elementName: String,
                             namespaceURI: String?,
                             qualifiedName qName: String?,
                             attributes attributeDict: [String: String]) {
            context.startElement(elementName,
                                 namespaceURI,
                                 attributeDict)

            if context.shouldAbort {
                parser.abortParsing()
            }
        }

        // internal func parser(_ parser: BaseXMLParser,
        //                      didStartMappingPrefix prefix: String,
        //                      toURI namespaceURI: String) {
        // }

        // internal func parser(_ parser: BaseXMLParser,
        //                      foundAttributeDeclarationWithName attributeName: String,
        //                      forElement elementName: String,
        //                      type: String?,
        //                      defaultValue: String?) {
        // }

        internal func parser(_ parser: BaseXMLParser,
                             foundCDATA CDATABlock: Data) {
            guard let string = String(data: CDATABlock,
                                      encoding: .utf8)
            else { return }

            context.appendText(string)
        }

        internal func parser(_ parser: BaseXMLParser,
                             foundCharacters string: String) {
            context.appendText(string)
        }

        // internal func parser(_ parser: BaseXMLParser,
        //                      foundComment comment: String) {
        // }

        // internal func parser(_ parser: BaseXMLParser,
        //                      foundElementDeclarationWithName elementName: String,
        //                      model: String) {
        // }

        // internal func parser(_ parser: BaseXMLParser,
        //                      foundExternalEntityDeclarationWithName name: String,
        //                      publicID: String?,
        //                      systemID: String?) {
        // }

        internal func parser(_ parser: BaseXMLParser,
                             foundIgnorableWhitespace whitespaceString: String) {
            // _appendText(whitespaceString)
        }

        // internal func parser(_ parser: BaseXMLParser,
        //                      foundInternalEntityDeclarationWithName name: String,
        //                      value: String?) {
        // }

        // internal func parser(_ parser: BaseXMLParser,
        //                      foundNotationDeclarationWithName name: String,
        //                      publicID: String?,
        //                      systemID: String?) {
        // }

        // internal func parser(_ parser: BaseXMLParser,
        //                      foundProcessingInstructionWithTarget target: String,
        //                      data: String?) {

        // internal func parser(_ parser: BaseXMLParser,
        //                      foundUnparsedEntityDeclarationWithName name: String,
        //                      publicID: String?,
        //                      systemID: String?,
        //                      notationName: String?) {
        // }

        internal func parser(_ parser: BaseXMLParser,
                             parseErrorOccurred parseError: any Swift.Error) {
            context.handleParseError(parser, parseError)
        }

        // internal func parser(_ parser: BaseXMLParser,
        //                      resolveExternalEntityName name: String,
        //                      systemID: String?) -> Data? {
        // }

        // internal func parser(_ parser: BaseXMLParser,
        //                      validationErrorOccurred validationError: Error) {
        // }

        // internal func parserDidEndDocument(_ parser: BaseXMLParser) {
        // }

        // internal func parserDidStartDocument(_ parser: BaseXMLParser) {
        // }
    }
}
