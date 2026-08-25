// © 2026 John Gary Pusey (see LICENSE.md)

extension XMLParser {

    // MARK: Public Nested Types

    /// The options that control how an ``XMLParser`` instance parses an XML
    /// document.
    public struct Options {

        // MARK: Public Initializers

        /// Creates a new set of parsing options.
        ///
        /// - Parameter stripsComments:                 Whether comments are
        ///                                             discarded rather than
        ///                                             represented in the
        ///                                             parsed XML document. The
        ///                                             default is `false`.
        /// - Parameter stripsProcessingInstructions:   Whether processing
        ///                                             instructions are
        ///                                             discarded rather than
        ///                                             represented in the
        ///                                             parsed XML document. The
        ///                                             default is `false`.
        public init(stripsComments: Bool = false,
                    stripsProcessingInstructions: Bool = false) {
            self.stripsComments = stripsComments
            self.stripsProcessingInstructions = stripsProcessingInstructions
        }

        // MARK: Public Instance Properties

        /// A Boolean value indicating whether comments are discarded rather than
        /// represented in the parsed XML document.
        ///
        /// If `false` (the default), each comment becomes a comment ``XMLNode``
        /// — among the children of the enclosing element, or in the prolog or
        /// epilog of the ``XMLDocument`` if it appears outside the root element.
        /// Otherwise, comments are ignored wherever they appear.
        ///
        /// Comments within the internal subset of a document type declaration
        /// are always ignored, since there is nowhere to represent them.
        public var stripsComments: Bool

        /// A Boolean value indicating whether processing instructions are
        /// discarded rather than represented in the parsed XML document.
        ///
        /// If `false` (the default), each processing instruction becomes a
        /// processing instruction ``XMLNode`` — among the children of the
        /// enclosing element, or in the prolog or epilog of the ``XMLDocument``
        /// if it appears outside the root element. Otherwise, processing
        /// instructions are ignored wherever they appear.
        ///
        /// Processing instructions within the internal subset of a document type
        /// declaration are always ignored, since there is nowhere to represent
        /// them. Note also that the XML declaration is _not_ a processing
        /// instruction; it is reported separately, as ``XMLDeclaration``.
        public var stripsProcessingInstructions: Bool
    }
}

// MARK: - Equatable

extension XMLParser.Options: Equatable {
}

// MARK: - Sendable

extension XMLParser.Options: Sendable {
}
