// © 2026 John Gary Pusey (see LICENSE.md)

internal import libxml2

private import Foundation
private import XestiTools

// An `EnhancedError` wrapper around a structured error reported by libxml2.
internal struct LibXMLError {

    // MARK: Internal Initializers

    internal init(_ error: xmlError) {
        self.code = error.code
        self.column = Int(error.int2)
        self.level = error.level.rawValue
        self.line = Int(error.line)
        self.text = error.message.map { String(cString: $0) }?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    // MARK: Internal Instance Properties

    internal let code: Int32
    internal let column: Int
    internal let level: UInt32
    internal let line: Int
    internal let text: String
}

// MARK: -

extension LibXMLError {

    // MARK: Internal Instance Properties

    //  libxml2 reports advisory diagnostics — an unsupported XML version, for
    //  example — through the very same channel as genuine defects,
    //  distinguished only by severity. Anything less severe than
    //  `XML_ERR_ERROR` leaves the document usable and must not be treated as a
    //  failure.
    internal var isFailure: Bool {
        level >= XML_ERR_ERROR.rawValue
    }
}

// MARK: - EnhancedError

extension LibXMLError: EnhancedError {

    // MARK: Internal Instance Properties

    internal var message: String {
        "libxml2 error \(code): \(text)"
    }
}

// MARK: - Sendable

extension LibXMLError: Sendable {
}
