// © 2022–2024 John Gary Pusey (see LICENSE.md)

import XestiTools

public enum XMLError {
    case internalFailure
    case invalidAttributeValue([String], String)
    case invalidElementValue([String], String)
    case missingRequiredAttribute(String, [String])
    case missingRequiredChildElement(String, [String])
    case parseFailure((any EnhancedError)?, Int, Int)
    case unexpectedElement(String, [String])
    case unexpectedRootElement(String)
    case unrecognizedAttribute(String, Int, Int)
    case unrecognizedElement(String, String?, Int, Int)
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
            if let uri, !uri.isEmpty {
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
