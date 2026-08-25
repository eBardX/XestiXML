// © 2026 John Gary Pusey (see LICENSE.md)

extension XMLFormatter {

    // MARK: Public Nested Types

    /// A binding of a namespace prefix to a namespace URI.
    ///
    /// An ``XMLNode`` tree records namespace _URIs_ only; the prefixes used to
    /// write them are chosen when the tree is formatted. A `Namespace` is how a
    /// caller makes that choice explicit, by way of
    /// ``XMLFormatter/Options/namespaces``. Any URI left unmentioned is still
    /// written correctly — it simply receives a generated prefix.
    public struct Namespace {

        // MARK: Public Initializers

        /// Creates a new binding of the provided prefix to the provided
        /// namespace URI.
        ///
        /// - Parameter prefix: The prefix to bind, or `nil` to make the URI the
        ///                     default namespace.
        /// - Parameter uri:    The namespace URI to bind the prefix to.
        public init(prefix: String?,
                    uri: String) {
            self.prefix = prefix
            self.uri = uri
        }

        // MARK: Public Instance Properties

        /// The prefix bound to the namespace URI.
        ///
        /// A `nil` prefix makes the URI the default namespace, written as
        /// `xmlns="…"`. Note that a default namespace applies to element names
        /// only: an unprefixed attribute name is in _no_ namespace, so an
        /// attribute in a namespace is always written with a real prefix, even
        /// when its URI is also the default namespace.
        public let prefix: String?

        /// The namespace URI the prefix is bound to.
        public let uri: String
    }
}

// MARK: - Hashable

extension XMLFormatter.Namespace: Hashable {
}

// MARK: - Sendable

extension XMLFormatter.Namespace: Sendable {
}
