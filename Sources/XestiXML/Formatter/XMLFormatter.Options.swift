// © 2026 John Gary Pusey (see LICENSE.md)

extension XMLFormatter {

    // MARK: Public Nested Types

    /// The options that control how an ``XMLFormatter`` instance formats an XML
    /// document.
    public struct Options {

        // MARK: Public Type Properties

        /// A set of options that formats the XML document as compactly as
        /// possible, on a single line, preceded by an XML declaration.
        public static var compact: Self {
            Self()
        }

        /// A set of options that formats the XML document for readability,
        /// indenting each nesting level by four spaces, preceded by an XML
        /// declaration.
        public static var pretty: Self {
            Self(indentation: 4)
        }

        // MARK: Public Initializers

        /// Creates a new set of formatting options.
        ///
        /// - Parameter emitsXMLDeclaration:            Whether the formatted
        ///                                             XML document is preceded
        ///                                             by an XML declaration.
        ///                                             The default is `true`.
        /// - Parameter indentation:                    The number of spaces by
        ///                                             which each nesting level
        ///                                             is indented, or `nil`
        ///                                             (the default) for no
        ///                                             indentation.
        /// - Parameter namespaces:                     The prefixes to bind to
        ///                                             the namespace URIs
        ///                                             appearing in the XML node
        ///                                             tree. The default is an
        ///                                             empty array.
        /// - Parameter stripsComments:                 Whether comments are
        ///                                             omitted from the
        ///                                             formatted XML document.
        ///                                             The default is `false`.
        /// - Parameter stripsProcessingInstructions:   Whether processing
        ///                                             instructions are omitted
        ///                                             from the formatted XML
        ///                                             document. The default is
        ///                                             `false`.
        public init(emitsXMLDeclaration: Bool = true,
                    indentation: Int? = nil,
                    namespaces: [Namespace] = [],
                    stripsComments: Bool = false,
                    stripsProcessingInstructions: Bool = false) {
            self.emitsXMLDeclaration = emitsXMLDeclaration
            self.indentation = indentation
            self.namespaces = namespaces
            self.stripsComments = stripsComments
            self.stripsProcessingInstructions = stripsProcessingInstructions
        }

        // MARK: Public Instance Properties

        /// A Boolean value indicating whether the formatted XML document is
        /// preceded by an XML declaration.
        ///
        /// If `true` (the default), an XML declaration is _always_ emitted: the
        /// one carried by the ``XMLDocument`` being formatted, completed as
        /// described by ``XMLFormatter``, or, if it has none, a declaration of
        /// `<?xml version="1.0" encoding="UTF-8" standalone="no"?>`.
        ///
        /// If `false`, the XML document is written in UTF-8 whatever its
        /// ``XMLDeclaration`` may name, since the declaration is the only thing
        /// that would tell a reader otherwise.
        ///
        /// Note that this option governs only the XML declaration. A document
        /// type declaration is emitted whenever the ``XMLDocument`` being
        /// formatted has one — unlike the XML declaration, it is never
        /// synthesized and cannot be suppressed, since it names the root
        /// element and identifies a specific DTD. Format a tree built without
        /// an ``XMLDocumentType`` to omit it.
        public var emitsXMLDeclaration: Bool

        /// The number of spaces by which each nesting level is indented.
        ///
        /// If `nil`, no indentation and no line breaks are applied; the entire
        /// XML document is formatted on a single line. Otherwise, each element
        /// appears on its own line, indented by the specified number of spaces
        /// per nesting level (a negative number is treated as zero).
        ///
        /// Note that indentation is _never_ applied to the children of an
        /// element with mixed content — that is, an element having at least one
        /// text node as a child — because doing so would alter the value of that
        /// element. The same applies to an element carrying
        /// `xml:space="preserve"`, whether or not it has a text node, and to all
        /// of its descendants.
        public var indentation: Int?

        /// The prefixes to bind to the namespace URIs appearing in the XML node
        /// tree.
        ///
        /// An ``XMLNode`` tree records namespace URIs, never prefixes, so the
        /// formatter chooses the prefixes. Every declaration is written on the
        /// root element, and this option says what those declarations are. It
        /// need not be exhaustive, and it is empty by default.
        ///
        /// A URI not listed here is still written correctly. It becomes the
        /// default namespace if _every_ element in the tree carries it;
        /// otherwise it receives a generated prefix (`ns1`, `ns2`, and so on)
        /// assigned in document order. So a document using a single namespace
        /// throughout needs no configuration at all.
        ///
        /// The prefix `xml` is bound to the XML namespace permanently and
        /// implicitly. It need not be declared, and cannot be bound to any other
        /// URI.
        ///
        /// Note that ``Error/invalidNamespace(_:_:)`` is thrown if a prefix is
        /// not a valid XML name without a colon, if a URI is empty, or if the
        /// same prefix or the same URI is bound twice.
        public var namespaces: [Namespace]

        /// A Boolean value indicating whether comments are omitted from the
        /// formatted XML document.
        ///
        /// If `false` (the default), each comment ``XMLNode`` is emitted where
        /// it appears. Otherwise, comments are omitted wherever they appear, and
        /// an element left with no children is emitted as an empty element.
        ///
        /// Note that an omitted comment is not validated, so a comment that
        /// could not otherwise be represented in an XML document does not cause
        /// ``Error/invalidCommentValue(_:)`` to be thrown.
        public var stripsComments: Bool

        /// A Boolean value indicating whether processing instructions are
        /// omitted from the formatted XML document.
        ///
        /// If `false` (the default), each processing instruction ``XMLNode`` is
        /// emitted where it appears. Otherwise, processing instructions are
        /// omitted wherever they appear, and an element left with no children is
        /// emitted as an empty element.
        ///
        /// Note that an omitted processing instruction is not validated, so one
        /// that could not otherwise be represented in an XML document does not
        /// cause ``Error/invalidProcessingInstructionTarget(_:)`` or
        /// ``Error/invalidProcessingInstructionData(_:_:)`` to be thrown. Note
        /// also that this option has no effect on the XML declaration, which is
        /// not a processing instruction; use ``emitsXMLDeclaration`` instead.
        public var stripsProcessingInstructions: Bool
    }
}

// MARK: - Equatable

extension XMLFormatter.Options: Equatable {
}

// MARK: - Sendable

extension XMLFormatter.Options: Sendable {
}
