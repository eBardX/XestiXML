// © 2022–2026 John Gary Pusey (see LICENSE.md)

import Foundation
import XestiTools

extension XMLParser {

    // MARK: Internal Nested Types

    internal struct Context {

        // MARK: Internal Nested Types

        internal typealias BaseXMLParser = Foundation.XMLParser

        // MARK: Internal Initializers

        internal init() {
            self.pendingAttributes = [:]
            self.pendingChildren = []
            self.pendingText = ""
            self.result = .failure(.internalFailure)
            self.savedContexts = []
            self.shouldAbort = false
        }

        // MARK: Internal Instance Properties

        internal private(set) var result: Result<XMLNode<E, A>, XMLError>
        internal private(set) var shouldAbort: Bool

        // MARK: Private Nested Types

        private typealias SavedContext = (E, [A: String], [XMLNode<E, A>])

        // MARK: Private Instance Properties

        private var pendingAttributes: [A: String]
        private var pendingChildren: [XMLNode<E, A>]
        private var pendingElement: E?
        private var pendingText: String
        private var savedContexts: [SavedContext]
        private var unrecognizedAttribute: String?
        private var unrecognizedElement: (String, String?)?
    }
}

// MARK: -

extension XMLParser.Context {

    // MARK: Internal Instance Methods

    internal mutating func appendText(_ text: String) {
        pendingText += text
    }

    internal mutating func endElement(_ name: String,
                                      _ uri: String?) {
        guard let elem = pendingElement,
              elem.name == name,
              elem.uri == uri
        else { return }

        flushText()

        let element: XMLNode<E, A> = XMLNode(element: elem,
                                             attributes: pendingAttributes,
                                             children: pendingChildren)

        if let context = savedContexts.popLast() {
            (pendingElement, pendingAttributes, pendingChildren) = context

            pendingChildren.append(element)
        } else {
            pendingAttributes = [:]
            pendingChildren = []
            pendingElement = nil

            result = .success(element)
        }
    }

    internal mutating func flushText() {
        let text = pendingText.normalizedXMLWhitespace()

        pendingText = ""

        guard !text.isEmpty
        else { return }

        pendingChildren.append(XMLNode(text: text))
    }

    internal mutating func handleParseError(_ parser: BaseXMLParser,
                                            _ parseError: any Swift.Error) {
        let code = BaseXMLParser.ErrorCode(rawValue: (parseError as NSError).code)
        let column = parser.columnNumber
        let line = parser.lineNumber

        var outError: XMLError

        switch code {
        case .delegateAbortedParseError:
            if let attr = unrecognizedAttribute {
                outError = .unrecognizedAttribute(attr, line, column)
            } else if let (name, uri) = unrecognizedElement {
                outError = .unrecognizedElement(name, uri, line, column)
            } else {
                fallthrough // swiftlint:disable:this fallthrough
            }

        default:
            outError = .parseFailure(parser.parserError as? any EnhancedError,
                                     line,
                                     column)
        }

        result = .failure(outError)
    }

    internal mutating func startElement(_ name: String,
                                        _ uri: String?,
                                        _ attributes: [String: String]) {
        flushText()

        guard let elem = E(name: name,
                           uri: uri)
        else {
            unrecognizedElement = (name, uri)
            shouldAbort = true

            return
        }

        if let pendElem = pendingElement {
            savedContexts.append((pendElem, pendingAttributes, pendingChildren))
        }

        pendingAttributes = [:]
        pendingChildren = []
        pendingElement = elem

        for (name, value) in attributes {
            guard let attr = A(name: name)
            else {
                unrecognizedAttribute = name
                shouldAbort = true

                return
            }

            pendingAttributes[attr] = value
        }
    }
}
