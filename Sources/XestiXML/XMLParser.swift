// © 2022–2026 John Gary Pusey (see LICENSE.md)

public import Foundation

private import XestiTools

/// A simplified XML parser.
///
/// `XMLParser` wraps the event-driven XML parser provided in `Foundation` and
/// hides all the machinery needed to build a type-safe tree of ``XMLNode``
/// instances representing the parsed XML document source. Essentially,
/// `XMLParser` converts an XML document into a very simple “DOM”. It is
/// _simple_ in that only elements, with any associated attributes, and text are
/// represented in the resulting tree. Other XML items (such as document type
/// declarations, processing instructions, comments, and ignorable whitespace
/// characters) are ignored. CDATA blocks are converted to text and external
/// entities are left unresolved.
///
/// Elements and attributes are mapped to custom ``XMLElement`` and
/// ``XMLAttribute`` types, respectively.
public struct XMLParser<E: XMLElement, A: XMLAttribute> {

    // MARK: Public Initializers

    /// Creates a new `XMLParser` instance.
    public init() {
    }
}

// MARK: -

extension XMLParser {

    // MARK: Public Instance Methods

    /// Parses the provided XML document.
    ///
    /// - Parameter data:   A `Data` instance containing the XML document to
    ///                     parse.
    ///
    /// - Returns:  The ``XMLNode`` representing the root element of the parsed
    ///             XML document..
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
