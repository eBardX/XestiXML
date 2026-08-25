// © 2026 John Gary Pusey (see LICENSE.md)

private import XestiTools

extension XMLFormatter {

    // MARK: Internal Nested Types

    // The prefix chosen for every namespace URI appearing in an XML node tree.
    //
    // An `XMLNode` tree records URIs, never prefixes, so the prefixes are
    // decided here — once, before anything is written — and every declaration
    // is emitted on the root element. Declaring at the root is what keeps the
    // writer free of namespace state: there is no scope to push, pop, or
    // restore, because no declaration is ever overridden.
    internal struct NamespaceTable {

        // MARK: Internal Initializers

        internal init() {
            self.declarations = []
            self.defaultURI = nil
            self.prefixes = [:]
        }

        //  Builds the table for the provided tree; throws
        //  `XMLFormatter.Error.invalidNamespace(_:_:)` if a binding in
        //  `options.namespaces` cannot be written.
        internal init(_ options: Options,
                      _ root: XMLNode<E, A>) throws(XMLFormatter.Error) {
            var explicitPrefixes: [String: String] = [:]
            var declarations: [(String?, String)] = []
            var defaultURI: String?
            var usedPrefixes: Set<String> = []

            for namespace in options.namespaces {
                let (prefix, uri) = (namespace.prefix, namespace.uri)

                try Self._validate(prefix, uri)

                guard explicitPrefixes[uri] == nil,
                      uri != defaultURI
                else { throw Error.invalidNamespace(prefix, uri) }

                if let prefix {
                    guard usedPrefixes.insert(prefix).inserted
                    else { throw Error.invalidNamespace(prefix, uri) }

                    explicitPrefixes[uri] = prefix
                } else {
                    guard defaultURI == nil
                    else { throw Error.invalidNamespace(prefix, uri) }

                    defaultURI = uri
                }

                declarations.append((prefix, uri))
            }

            var elementURIs: [String] = []
            var attributeURIs: [String] = []
            var hasUnnamespacedElement = false

            Self._collect(root,
                          &elementURIs,
                          &attributeURIs,
                          &hasUnnamespacedElement)

            //
            // A lone namespace covering every element in the tree becomes the
            // default, which is both what the caller almost always wants and
            // what keeps the output of a single-namespace document free of
            // prefixes. The moment one element sits outside it, that no longer
            // works — undeclaring with `xmlns=""` would be needed — so a prefix
            // is used instead.
            //
            if defaultURI == nil,
               !hasUnnamespacedElement,
               elementURIs.count == 1,
               let onlyURI = elementURIs.first,
               explicitPrefixes[onlyURI] == nil,
               onlyURI != xmlNamespaceURI {
                defaultURI = onlyURI

                declarations.append((nil, onlyURI))
            }

            var counter = 0

            //
            // An attribute is never in the default namespace: an unprefixed
            // attribute name is in no namespace at all, so an attribute URI
            // always needs a real prefix, even the one already serving as the
            // default. Element URIs come first so that prefix numbering follows
            // document order.
            //
            for uri in elementURIs.filter({ $0 != defaultURI }) + attributeURIs
            where explicitPrefixes[uri] == nil && uri != xmlNamespaceURI {
                try Self._validate(nil, uri)

                var prefix: String

                repeat {
                    counter += 1

                    prefix = "ns\(counter)"
                } while !usedPrefixes.insert(prefix).inserted

                explicitPrefixes[uri] = prefix

                declarations.append((prefix, uri))
            }

            self.declarations = declarations
            self.defaultURI = defaultURI
            self.prefixes = explicitPrefixes
        }

        // MARK: Internal Instance Properties

        //  Every declaration to write on the root element, in emission order.
        internal let declarations: [(String?, String)]

        // MARK: Private Instance Properties

        private let defaultURI: String?
        private let prefixes: [String: String]
    }
}

// MARK: -

extension XMLFormatter.NamespaceTable {

    // MARK: Internal Instance Methods

    //  Unlike an element name, an attribute name is never left unprefixed to
    //  pick up the default namespace, because an unprefixed attribute is in no
    //  namespace at all.
    internal func attributeName(_ name: String,
                                _ uri: String?) -> String {
        guard let uri
        else { return name }

        return _prefixed(name, uri)
    }

    internal func elementName(_ name: String,
                              _ uri: String?) -> String {
        guard let uri,
              uri != defaultURI
        else { return name }

        return _prefixed(name, uri)
    }

    // MARK: Private Type Methods

    //  Walks the tree once, gathering the distinct element and attribute URIs in
    //  document order.
    private static func _collect(_ node: XMLNode<E, A>,
                                 _ elementURIs: inout [String],
                                 _ attributeURIs: inout [String],
                                 _ hasUnnamespacedElement: inout Bool) {
        guard case let .element(element, attributes, children) = node.content
        else { return }

        if let uri = element.uri?.nilIfEmpty {
            if !elementURIs.contains(uri) {
                elementURIs.append(uri)
            }
        } else {
            hasUnnamespacedElement = true
        }

        for uri in attributes.keys.compactMap({ $0.uri?.nilIfEmpty }).sorted()
        where !attributeURIs.contains(uri) {
            attributeURIs.append(uri)
        }

        for child in children {
            _collect(child,
                     &elementURIs,
                     &attributeURIs,
                     &hasUnnamespacedElement)
        }
    }

    private static func _validate(_ prefix: String?,
                                  _ uri: String) throws(XMLFormatter.Error) {
        //
        // The XML namespace is bound to `xml` permanently and implicitly, and
        // the xmlns namespace cannot be bound at all.
        //
        guard !uri.isEmpty,
              uri.isXMLCharacters,
              uri != xmlNamespaceURI,
              uri != xmlnsNamespaceURI
        else { throw XMLFormatter.Error.invalidNamespace(prefix, uri) }

        guard let prefix
        else { return }

        guard prefix.isXMLNCName,
              prefix != "xml",
              prefix != "xmlns"
        else { throw XMLFormatter.Error.invalidNamespace(prefix, uri) }
    }

    // MARK: Private Instance Methods

    private func _prefixed(_ name: String,
                           _ uri: String) -> String {
        guard uri != xmlNamespaceURI
        else { return "xml:\(name)" }

        guard let prefix = prefixes[uri]
        else { return name }

        return "\(prefix):\(name)"
    }
}

// MARK: - Private Constants

private let xmlNamespaceURI   = "http://www.w3.org/XML/1998/namespace"
private let xmlnsNamespaceURI = "http://www.w3.org/2000/xmlns/"
