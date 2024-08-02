// © 2022–2024 John Gary Pusey (see LICENSE.md)

import Foundation
import XestiTools

public final class XMLParser<E: XMLElement, A: XMLAttribute>: NSObject, XMLParserDelegate {

    // MARK: Public Nested Types

    public typealias BaseXMLParser = Foundation.XMLParser
    public typealias ParsedXMLNode = XMLNode<E, A>

    // MARK: Public Initializers

    public init(_ data: Data) {
        self.baseParser = .init(data: data)
        self.pendingChildren = []
        self.pendingText = ""
        self.savedContexts = []

        super.init()

        baseParser.delegate = self
        baseParser.shouldProcessNamespaces = true
    }

    // MARK: Public Instance Methods

    public func parse() throws -> ParsedXMLNode {
        guard  baseParser.parse(),
               let resultNode
        else { throw resultError ?? baseParser.parserError ?? XMLError.internalFailure }

        return resultNode
    }

    // MARK: Private Instance Properties

    private let baseParser: BaseXMLParser

    private var pendingChildren: [ParsedXMLNode]
    private var pendingElement: E?
    private var pendingText: String
    private var resultError: XMLError?
    private var resultNode: ParsedXMLNode?
    private var savedContexts: [(E, [ParsedXMLNode])]
    private var unrecognizedAttribute: String?
    private var unrecognizedElement: (String, String?)?

    // MARK: Private Instance Methods

    private func _appendText(_ text: String) {
        pendingText += text
    }

    private func _endElement(_ name: String,
                             _ uri: String) {
        guard let elem = pendingElement,
              elem.name == name,
              elem.uri == uri
        else { return }

        _flushText()

        let element: ParsedXMLNode = .elem(elem, pendingChildren)

        if let context = savedContexts.popLast() {
            (pendingElement, pendingChildren) = context

            pendingChildren.append(element)
        } else {
            pendingChildren = []
            pendingElement = nil

            resultNode = element
        }
    }

    private func _flushText() {
        let text = pendingText.normalizedXMLWhitespace()

        pendingText = ""

        guard !text.isEmpty
        else { return }

        pendingChildren.append(.text(text))
    }

    private func _startElement(_ name: String,
                               _ uri: String,
                               _ attributes: [String: String]) {
        _flushText()

        if let elem = E(name, uri) {
            if let pendElem = pendingElement {
                savedContexts.append((pendElem, pendingChildren))
            }

            pendingChildren = []
            pendingElement = elem

            for (name, value) in attributes {
                if let attr = A(name) {
                    pendingChildren.append(.attr(attr, value))
                } else {
                    unrecognizedAttribute = name

                    baseParser.abortParsing()
                }
            }
        } else {
            unrecognizedElement = (name, uri)

            baseParser.abortParsing()
        }
    }

    // MARK: XMLParserDelegate

    public func parser(_ parser: BaseXMLParser,
                       didEndElement elementName: String,
                       namespaceURI: String?,
                       qualifiedName qName: String?) {
        _endElement(elementName,
                    namespaceURI ?? "")
    }

    // public func parser(_ parser: BaseXMLParser,
    //                    didEndMappingPrefix prefix: String) {
    // }

    public func parser(_ parser: BaseXMLParser,
                       didStartElement elementName: String,
                       namespaceURI: String?,
                       qualifiedName qName: String?,
                       attributes attributeDict: [String: String]) {
        _startElement(elementName,
                      namespaceURI ?? "",
                      attributeDict)
    }

    // public func parser(_ parser: BaseXMLParser,
    //                    didStartMappingPrefix prefix: String,
    //                    toURI namespaceURI: String) {
    // }

    // public func parser(_ parser: BaseXMLParser,
    //                    foundAttributeDeclarationWithName attributeName: String,
    //                    forElement elementName: String,
    //                    type: String?,
    //                    defaultValue: String?) {
    // }

    public func parser(_ parser: BaseXMLParser,
                       foundCDATA CDATABlock: Data) {
        guard let string = String(data: CDATABlock,
                                  encoding: .utf8)
        else { return }

        _appendText(string)
    }

    public func parser(_ parser: BaseXMLParser,
                       foundCharacters string: String) {
        _appendText(string)
    }

    // public func parser(_ parser: BaseXMLParser,
    //                    foundComment comment: String) {
    // }

    // public func parser(_ parser: BaseXMLParser,
    //                    foundElementDeclarationWithName elementName: String,
    //                    model: String) {
    // }

    // public func parser(_ parser: BaseXMLParser,
    //                    foundExternalEntityDeclarationWithName name: String,
    //                    publicID: String?,
    //                    systemID: String?) {
    // }

    public func parser(_ parser: BaseXMLParser,
                       foundIgnorableWhitespace whitespaceString: String) {
        // _appendText(whitespaceString)
    }

    // public func parser(_ parser: BaseXMLParser,
    //                    foundInternalEntityDeclarationWithName name: String,
    //                    value: String?) {
    // }

    // public func parser(_ parser: BaseXMLParser,
    //                    foundNotationDeclarationWithName name: String,
    //                    publicID: String?,
    //                    systemID: String?) {
    // }

    // public func parser(_ parser: BaseXMLParser,
    //                    foundProcessingInstructionWithTarget target: String,
    //                    data: String?) {

    // public func parser(_ parser: BaseXMLParser,
    //                    foundUnparsedEntityDeclarationWithName name: String,
    //                    publicID: String?,
    //                    systemID: String?,
    //                    notationName: String?) {
    // }

    public func parser(_ parser: BaseXMLParser,
                       parseErrorOccurred parseError: any Swift.Error) {
        let code = BaseXMLParser.ErrorCode(rawValue: (parseError as NSError).code)
        let column = parser.columnNumber
        let line = parser.lineNumber

        switch code {
        case .delegateAbortedParseError:
            if let attr = unrecognizedAttribute {
                resultError = .unrecognizedAttribute(attr, line, column)
            } else if let (name, uri) = unrecognizedElement {
                resultError = .unrecognizedElement(name, uri, line, column)
            } else {
                fallthrough // swiftlint:disable:this fallthrough
            }

        default:
            resultError = .parseFailure(parser.parserError as? (any EnhancedError), line, column)
        }
    }

    // public func parser(_ parser: BaseXMLParser,
    //                    resolveExternalEntityName name: String,
    //                    systemID: String?) -> Data? {
    // }

    // public func parser(_ parser: BaseXMLParser,
    //                    validationErrorOccurred validationError: Error) {
    // }

    // public func parserDidEndDocument(_ parser: BaseXMLParser) {
    // }

    // public func parserDidStartDocument(_ parser: BaseXMLParser) {
    // }
}
