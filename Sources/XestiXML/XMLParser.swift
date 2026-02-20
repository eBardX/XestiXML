// © 2022–2026 John Gary Pusey (see LICENSE.md)

import Foundation
import XestiTools

public struct XMLParser<E: XMLElement, A: XMLAttribute> {

    // MARK: Public Initializers

    public init() {
    }
}

// MARK: -

extension XMLParser {

    // MARK: Public Instance Methods

    public func parse(_ data: Data) throws -> XMLNode<E, A> {
        let baseParser = BaseXMLParser(data: data)
        let delegate = Delegate()

        baseParser.delegate = delegate
        baseParser.shouldProcessNamespaces = true

        guard baseParser.parse()
        else { throw (delegate.context.result.failure
                      ?? baseParser.parserError
                      ?? XMLError.internalFailure) }

        return try delegate.context.result.get()
    }

    // MARK: Private Nested Types

    private typealias BaseXMLParser = Foundation.XMLParser
}
