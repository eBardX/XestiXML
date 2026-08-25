// © 2026 John Gary Pusey (see LICENSE.md)

/// The document type declaration of an XML document.
///
/// A document type declaration is the `<!DOCTYPE … >` that may precede the root
/// element. Only its _header_ — the root element name and the optional external
/// identifier — is represented here; any declarations in an internal subset are
/// ignored.
///
/// The external identifier is never resolved. External DTD subsets are not
/// loaded from the network or from the file system, so a document type
/// declaration is carried purely so that it survives a round trip. This matters
/// for document types identified by their `<!DOCTYPE>` rather than by a
/// namespace, such as MusicXML.
public struct XMLDocumentType {

    // MARK: Public Initializers

    /// Creates a new document type declaration.
    ///
    /// - Parameter name:       The name of the root element.
    /// - Parameter publicID:   The public identifier of the external DTD subset,
    ///                         or `nil` (the default) if there is none.
    /// - Parameter systemID:   The system identifier of the external DTD subset,
    ///                         or `nil` (the default) if there is none.
    public init(name: String,
                publicID: String? = nil,
                systemID: String? = nil) {
        self.name = name
        self.publicID = publicID
        self.systemID = systemID
    }

    // MARK: Public Instance Properties

    /// The name of the root element.
    public let name: String

    /// The public identifier of the external DTD subset, or `nil` if there is
    /// none.
    ///
    /// A public identifier is meaningful only alongside a system identifier;
    /// one without the other cannot be formatted.
    public let publicID: String?

    /// The system identifier of the external DTD subset, or `nil` if there is
    /// none.
    public let systemID: String?
}

// MARK: - Equatable

extension XMLDocumentType: Equatable {
}

// MARK: - Sendable

extension XMLDocumentType: Sendable {
}
