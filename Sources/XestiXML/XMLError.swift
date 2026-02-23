// © 2022–2026 John Gary Pusey (see LICENSE.md)

import XestiTools

/// An error that occurs while parsing the XML document or while matching the
/// XML node tree.
public enum XMLError {
    /// Some otherwise unspecified failure has occurred while parsing the XML
    /// document.
    case internalFailure

    /// An invalid attribute value was encountered while matching the XML node
    /// tree.
    ///
    /// As associated values, this case contains a list of the names of
    /// acceptable attributes, as well as the invalid attribute value.
    case invalidAttributeValue([String], String)

    /// An invalid element value was encountered while matching the XML node
    /// tree.
    ///
    /// As associated values, this case contains a list of the names of
    /// acceptable elements, as well as the invalid element value.
    case invalidElementValue([String], String)

    /// An element in the XML node tree is missing a required attribute.
    ///
    /// As associated values, this case contains the name of the element, as
    /// well as a list of the names of acceptable attributes.
    case missingRequiredAttribute(String, [String])

    /// An element in the XML node tree is missing a required child element.
    ///
    /// As associated values, this case contains the name of the parent element,
    /// as well as a list of the names of acceptable child elements.
    case missingRequiredChildElement(String, [String])

    /// A failure was encountered by the underlying base XML parser while
    /// parsing the XML document.
    ///
    /// As associated values, this case contains the parse error reported by the
    /// underlying base XML parser, as well as the line and column in the XML
    /// document.
    case parseFailure((any EnhancedError)?, Int, Int)

    /// An unexpected element was encountered in the XML node tree.
    ///
    /// As associated values, this case contains the unexpected element name, as
    /// well as a list of expected element names.
    case unexpectedElement(String, [String])

    /// An unexpected root element was encountered in the XML node tree.
    ///
    /// As an associated value, this case contains the unexpected root element
    /// name.
    case unexpectedRootElement(String)

    /// An unrecognized attribute name was encountered while parsing the XML
    /// document.
    ///
    /// As associated values, this case contains the unrecognized attribute
    /// name, as well as the line and column in the XML document.
    case unrecognizedAttribute(String, Int, Int)

    /// An unrecognized element name or namespace URI was encountered while
    /// parsing the XML document.
    ///
    /// As associated values, this case contains the unrecognized element name
    /// and optional namespace URI, as well as the line and column in the XML
    /// document.
    case unrecognizedElement(String, String?, Int, Int)

    /// An unsupported root element was encountered in the XML node tree.
    ///
    /// As an associated value, this case contains the unsupported root element
    /// name.
    case unsupportedRootElement(String)
}

// MARK: - EnhancedError

extension XMLError: EnhancedError {
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

        case let .invalidAttributeValue(names, value):
            "Invalid value for \(_formatAttributes(names)) attribute: \(value)"

        case let .invalidElementValue(names, value):
            "Invalid value for \(_formatElements(names)) element: \(value)"

        case let .missingRequiredAttribute(eltName, attNames):
            "Missing required \(_formatAttributes(attNames)) attribute for \(_formatElement(eltName)) element"

        case let .missingRequiredChildElement(parName, chdNames):
            "Missing required \(_formatElements(chdNames)) element as child of \(_formatElement(parName)) element"

        case let .parseFailure(_, line, column):
            "Unable to parse XML data, line: \(line), column: \(column)"

        case let .unexpectedElement(actName, expNames):
            "Unexpected element: \(_formatElement(actName)), expected: \(_formatElements(expNames))"

        case let .unexpectedRootElement(name):
            "Unexpected root element: \(_formatElement(name))"

        case let .unrecognizedAttribute(name, line, column):
            "Unrecognized attribute name: \(name), line: \(line), column: \(column)"

        case let .unrecognizedElement(name, uri, line, column):
            if let uri {
                "Unrecognized element name: \(name), uri: \(uri), line: \(line), column: \(column)"
            } else {
                "Unrecognized element name: \(name), line: \(line), column: \(column)"
            }

        case let .unsupportedRootElement(name):
            "Unsupported root element: \(_formatElement(name))"
        }
    }

    // MARK: Private Instance Methods

    private func _formatAttribute(_ name: String) -> String {
        name
    }

    private func _formatAttributes(_ names: [String]) -> String {
        _formatList(names) { _formatAttribute($0) }
    }

    private func _formatElement(_ name: String) -> String {
        "<" + name + ">"
    }

    private func _formatElements(_ names: [String]) -> String {
        _formatList(names) { _formatElement($0) }
    }

    private func _formatList<T>(_ items: [T],
                                empty: String = "(unknown)",
                                separator: String = ", ",
                                separator2: String = " or ",
                                separatorN: String = ", or ",
                                format: (T) -> String) -> String {
        let fmtItems = items.map(format)

        switch fmtItems.count {
        case 0:
            return empty

        case 1:
            return fmtItems[0]

        case 2:
            return fmtItems[0] + separator2 + fmtItems[1]

        default:
            return fmtItems.dropLast().joined(separator: separator) + separatorN + fmtItems[fmtItems.count - 1]
        }
    }
}

// MARK: - Sendable

extension XMLError: Sendable {
}
