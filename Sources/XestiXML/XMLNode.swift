// © 2022–2026 John Gary Pusey (see LICENSE.md)

/// A node in the abstract, logical tree structure that represents an XML document.
///
/// There are two kinds of `XMLNode` — _element_ or _text_:
///
/// - An element node consists of three components:
///
///   1. A type-safe ``XMLElement`` instance encapsulating the element name and
///      the optional namespace URI.
///   2. A dictionary of associated attributes where the key is a type-safe
///      ``XMLAttribute`` instance encapsulating the attribute name, and the
///      value is the attribute (string) value. This dictionary may be empty.
///   3. An array of child `XMLNode` instances. This array may be empty.
///
/// - A text node consists of string value.
public struct XMLNode<E: XMLElement, A: XMLAttribute> {

    // MARK: Public Initializers

    /// Creates a new element node.
    ///
    /// - Parameter element:    An ``XMLElement`` instance,
    /// - Parameter attributes: A dictionary of associated attributes.
    /// - Parameter children:   An array of child `XMLNode` instances.
    public init(element: E,
                attributes: [A: String],
                children: [Self]) {
        self.content = .elem(element, attributes, children)
    }

    /// Creates a new text node.
    ///
    /// - Parameter text:   A string value.
    public init(text: String) {
        self.content = .text(text)
    }

    // MARK: Internal Instance Properties

    internal let content: Content
}

// MARK: -

extension XMLNode {

    // MARK: Public Instance Properties

    /// A dictionary of associated attributes, if this instance is an element
    /// node; otherwise, `nil`.
    public var attributes: [A: String]? {
        switch content {
        case let .elem(_, attrs, _):
            attrs

        default:
            nil
        }
    }

    /// An array of child `XMLNode` instances, if this instance is an element
    /// node; otherwise, `nil`.
    public var children: [Self]? {
        switch content {
        case let .elem(_, _, kids):
            kids

        default:
            nil
        }
    }

    /// An ``XMLElement`` instance, if this instance is an element node;
    /// otherwise, `nil`.
    public var element: E? {
        switch content {
        case let .elem(elem, _, _):
            elem

        default:
            nil
        }
    }

    /// A Boolean value indicating whether this instance is an element node.
    public var isElement: Bool {
        switch content {
        case .elem:
            true

        default:
            false
        }
    }

    /// A Boolean value indicating whether this instance is a text node.
    public var isText: Bool {
        switch content {
        case .text:
            true

        default:
            false
        }
    }

    /// An element name, if this instance is an element node; otherwise, `nil`.
    public var name: String? {
        switch content {
        case let .elem(elem, _, _):
            elem.name

        default:
            nil
        }
    }

    /// A namespace URI, if this instance is an element node; otherwise `nil`.
    public var uri: String? {
        switch content {
        case let .elem(elem, _, _):
            elem.uri

        default:
            nil
        }
    }

    /// The concatenation of the string values of all descendent text nodes of
    /// this instance.
    public var value: String? {
        switch content {
        case .elem:
            _valueOfElement()

        case let .text(value):
            value
        }
    }

    // MARK: Public Instance Methods

    /// Returns an array of all child element nodes of this instance.
    ///
    /// - Returns:  An array of all child element nodes. If this instance is not
    ///             an element node, this method returns an empty array.
    public func allChildElements() -> [Self] {
        children?.filter { $0.isElement } ?? []
    }

    /// Returns an array of all child element nodes of this instance matching
    /// the provided ``XMLElement`` instance.
    ///
    /// - Parameter elem:   An ``XMLElement`` instance to match.
    ///
    /// - Returns:  An array of all matching child element nodes. If this
    ///             instance is not an element node, or if there are no matches,
    ///             this method returns an empty array.
    public func allChildElements(_ elem: E) -> [Self] {
        allChildElements([elem])
    }

    /// Returns an array of all child element nodes of this instance matching
    /// any of the provided ``XMLElement`` instances.
    ///
    /// - Parameter elems:  An array of ``XMLElement`` instances to match.
    ///
    /// - Returns:  An array of all matching child element nodes. If this
    ///             instance is not an element node, or if there are no matches,
    ///             this method returns an empty array.
    public func allChildElements(_ elems: [E]) -> [Self] {
        children?.filter { $0.isElement(elems) } ?? []
    }

    /// Returns the first child element node of this instance matching the provided
    /// ``XMLElement`` instance.
    ///
    /// - Parameter elem:   An ``XMLElement`` instance to match.
    ///
    /// - Returns:  The first matching child element node. If this instance is
    ///             not an element node, or if there are no matches, this method
    ///             returns `nil`.
    public func firstChildElement(_ elem: E) -> Self? {
        firstChildElement([elem])
    }

    /// Returns the first child element node of this instance matching any of
    /// the provided ``XMLElement`` instances.
    ///
    /// - Parameter elems:  An array of ``XMLElement`` instances to match.
    ///
    /// - Returns:  The first matching child element node. If this instance is
    ///             not an element node, or if there are no matches, this method
    ///             returns `nil`.
    public func firstChildElement(_ elems: [E]) -> Self? {
        children?.first { $0.isElement(elems) }
    }

    /// Returns a Boolean value indicating whether this instance is an element
    /// node matching the provided ``XMLElement`` instance.
    ///
    /// - Parameter elem:   An ``XMLElement`` instance to match.
    ///
    /// - Returns:  `true` if this instance is a matching element node;
    ///             otherwise, `false`.
    public func isElement(_ elem: E) -> Bool {
        isElement([elem])
    }

    /// Returns a Boolean value indicating whether this instance is an element
    /// node matching any of the provided ``XMLElement`` instances.
    ///
    /// - Parameter elems:  An array of ``XMLElement`` instances to match.
    ///
    /// - Returns:  `true` if this instance is a matching element node;
    ///             otherwise, `false`.
    public func isElement(_ elems: [E]) -> Bool {
        switch content {
        case let .elem(candElem, _, _):
            elems.contains(candElem)

        default:
            false
        }
    }

    // MARK: Private Instance Methods

    private func _valueOfElement() -> String? {
        children?.reduce(into: "") { result, node in
            switch node.content {
            case .elem:
                if let value = node._valueOfElement() {
                    result += value
                }

            case let .text(value):
                result += value
            }
        }
    }
}

// MARK: - CustomStringConvertible

extension XMLNode: CustomStringConvertible {
    public var description: String {
        switch content {
        case let .elem(elem, attrs, kids):
            var result = "<\(elem.name)"

            for (attr, val) in attrs.sorted(by: { $0.key.name < $1.key.name }) {
                result += " \(attr.name)=\"\(val)\""
            }

            result += ">"

            if !kids.isEmpty {
                result += kids.map(\.description).joined()
            }

            result += "</\(elem.name)>"

            return result

        case let .text(value):
            return "\"\(value)\""
        }
    }
}

// MARK: - Sendable

extension XMLNode: Sendable {
}
