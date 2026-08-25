// © 2022–2026 John Gary Pusey (see LICENSE.md)

public import XestiTools

extension XMLParser {

    // MARK: Public Nested Types

    /// An error that occurs while parsing the XML document or while matching the
    /// XML node tree.
    ///
    /// Additional cases may be added in a future release, so prefer a `default`
    /// case when switching over an `Error` value; an exhaustive switch will stop
    /// compiling when one is.
    public enum Error {
        /// Some otherwise unspecified failure has occurred while parsing the XML
        /// document.
        case internalFailure

        /// A failure was encountered by the underlying base XML parser while
        /// parsing the XML document.
        ///
        /// As associated values, this case contains the parse error reported
        /// by the underlying base XML parser, as well as the line and column
        /// in the XML document.
        case parseFailure((any EnhancedError)?, Int, Int)

        /// An unrecognized attribute name was encountered while parsing the XML
        /// document.
        ///
        /// As associated values, this case contains the unrecognized attribute
        /// name, as well as the line and column in the XML document.
        case unrecognizedAttribute(String, Int, Int)

        /// An unrecognized element name or namespace URI was encountered while
        /// parsing the XML document.
        ///
        /// As associated values, this case contains the unrecognized element
        /// name and optional namespace URI, as well as the line and column in
        /// the XML document.
        case unrecognizedElement(String, String?, Int, Int)
    }
}

// MARK: - EnhancedError

extension XMLParser.Error: EnhancedError {

    // MARK: Public Instance Properties

    public var cause: (any EnhancedError)? {
        switch self {
        case let .parseFailure(error, _, _):
            error

        default:
            nil
        }
    }

    public var message: String {
        switch self {
        case .internalFailure:
            "Internal failure"

        case let .parseFailure(_, line, column):
            "Unable to parse XML data, line: \(line), column: \(column)"

        case let .unrecognizedAttribute(name, line, column):
            "Unrecognized attribute name: \(name), line: \(line), column: \(column)"

        case let .unrecognizedElement(name, uri, line, column):
            if let uri {
                "Unrecognized element name: \(name), uri: \(uri), line: \(line), column: \(column)"
            } else {
                "Unrecognized element name: \(name), line: \(line), column: \(column)"
            }
        }
    }
}

// MARK: - Sendable

extension XMLParser.Error: Sendable {
}
