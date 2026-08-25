// © 2026 John Gary Pusey (see LICENSE.md)

/// The XML declaration at the head of an XML document.
///
/// An XML declaration is the `<?xml … ?>` that may precede everything else in
/// a document. It is not a processing instruction, and it is not part of the
/// XML node tree; it belongs to the ``XMLDocument`` that contains that tree.
///
/// An instance describes a declaration in either direction: one reported by
/// ``XMLParser`` for a document it has read, or one constructed directly for
/// ``XMLFormatter`` to write.
public struct XMLDeclaration {

    // MARK: Public Initializers

    /// Creates a new XML declaration.
    ///
    /// - Parameter version:        The XML version. The default is `"1.0"`.
    /// - Parameter encoding:       The declared character encoding, or `nil`
    ///                             (the default) if there is none.
    /// - Parameter isStandalone:   Whether the document is declared standalone,
    ///                             or `nil` (the default) if there is no
    ///                             `standalone` pseudo-attribute.
    public init(version: String = "1.0",
                encoding: String? = nil,
                isStandalone: Bool? = nil) {
        self.encoding = encoding
        self.isStandalone = isStandalone
        self.version = version
    }

    // MARK: Public Instance Properties

    /// The declared character encoding, or `nil` if there is none.
    ///
    /// An XML document whose declaration names no encoding, and which carries
    /// no byte order mark, is encoded in UTF-8.
    ///
    /// ``XMLFormatter`` writes the bytes of a document in the encoding named
    /// here, so this is a request as well as a description.
    public let encoding: String?

    /// A Boolean value indicating whether the document is declared standalone,
    /// or `nil` if there is no `standalone` pseudo-attribute.
    ///
    /// Note that `nil` and `false` are _not_ equivalent: the former means the
    /// pseudo-attribute is absent, and the latter means it is present as
    /// `standalone="no"`. They mean the same thing to an XML processor, which
    /// assumes `no` for an absent pseudo-attribute, so ``XMLFormatter`` writes
    /// both as `standalone="no"`; the distinction is kept here because it is a
    /// distinction the document itself makes.
    public let isStandalone: Bool?

    /// The XML version.
    public let version: String
}

// MARK: - Equatable

extension XMLDeclaration: Equatable {
}

// MARK: - Sendable

extension XMLDeclaration: Sendable {
}
