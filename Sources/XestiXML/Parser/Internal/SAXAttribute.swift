// © 2026 John Gary Pusey (see LICENSE.md)

// One attribute as libxml2 reports it, carried across the non-generic
// boundary.
//
// libxml2 supplies the local name and the namespace URI separately, and never
// includes a namespace declaration among them. The prefix it also supplies is
// deliberately dropped: it is a lexical accident of the source, and an
// `XMLAttribute` is identified by local name and URI alone.
//
// This is an array rather than a dictionary because two attributes can share a
// local name while differing in namespace — `a:id` and a plain `id` are
// distinct attributes — and a dictionary keyed on the name alone would
// silently discard one of them.
internal struct SAXAttribute {

    // MARK: Internal Initializers

    internal init(_ name: String,
                  _ uri: String?,
                  _ value: String) {
        self.name = name
        self.uri = uri
        self.value = value
    }

    // MARK: Internal Instance Properties

    internal let name: String
    internal let uri: String?
    internal let value: String
}
