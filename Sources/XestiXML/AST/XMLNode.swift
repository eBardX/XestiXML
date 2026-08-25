// © 2022–2026 John Gary Pusey (see LICENSE.md)

/// A node in the abstract, logical tree structure that represents an XML
/// document.
///
/// There are four kinds of `XMLNode` — _element_, _text_, _comment_, or
/// _processing instruction_:
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
/// - A text node consists of a string value.
///
/// - A comment node consists of the text between its delimiters.
///
/// - A processing instruction node consists of a target and optional data.
///
/// Note that comments and processing instructions are retained unless
/// ``XMLParser`` is asked to discard them, or ``XMLFormatter`` is asked to omit
/// them; see ``XMLParser/Options`` and ``XMLFormatter/Options``.
public struct XMLNode<E: XMLElement, A: XMLAttribute> {

    // MARK: Public Initializers

    /// Creates a new comment node.
    ///
    /// - Parameter comment:    The text between the comment delimiters.
    public init(comment: String) {
        self.content = .comment(comment)
    }

    /// Creates a new element node.
    ///
    /// - Parameter element:    An ``XMLElement`` instance.
    /// - Parameter attributes: A dictionary of associated attributes. The
    ///                         default is an empty dictionary.
    /// - Parameter children:   An array of child `XMLNode` instances. The
    ///                         default is an empty array.
    public init(element: E,
                attributes: [A: String] = [:],
                children: [Self] = []) {
        self.content = .element(element, attributes, children)
    }

    /// Creates a new processing instruction node.
    ///
    /// - Parameter processingInstruction:  The target of the processing
    ///                                     instruction.
    /// - Parameter data:                   The data of the processing
    ///                                     instruction, or `nil` (the default)
    ///                                     if there is none.
    public init(processingInstruction: String,
                data: String? = nil) {
        self.content = .processingInstruction(processingInstruction, data)
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

    /// A dictionary of associated attributes, if this node is an element node;
    /// otherwise, `nil`.
    public var attributes: [A: String]? {
        switch content {
        case let .element(_, attrs, _):
            attrs

        default:
            nil
        }
    }

    /// An array of child `XMLNode` instances, if this node is an element node;
    /// otherwise, `nil`.
    public var children: [Self]? {
        switch content {
        case let .element(_, _, kids):
            kids

        default:
            nil
        }
    }

    /// The text between the comment delimiters, if this node is a comment node;
    /// otherwise, `nil`.
    public var comment: String? {
        switch content {
        case let .comment(text):
            text

        default:
            nil
        }
    }

    /// The data of the processing instruction, if this node is a processing
    /// instruction node having data; otherwise, `nil`.
    public var data: String? {
        switch content {
        case let .processingInstruction(_, data):
            data

        default:
            nil
        }
    }

    /// An ``XMLElement`` instance, if this node is an element node; otherwise,
    /// `nil`.
    public var element: E? {
        switch content {
        case let .element(elem, _, _):
            elem

        default:
            nil
        }
    }

    /// A Boolean value indicating whether this node is a comment node.
    public var isComment: Bool {
        switch content {
        case .comment:
            true

        default:
            false
        }
    }

    /// A Boolean value indicating whether this node is an element node.
    public var isElement: Bool {
        switch content {
        case .element:
            true

        default:
            false
        }
    }

    /// A Boolean value indicating whether this node is a processing instruction
    /// node.
    public var isProcessingInstruction: Bool {
        switch content {
        case .processingInstruction:
            true

        default:
            false
        }
    }

    /// A Boolean value indicating whether this node is a text node.
    public var isText: Bool {
        switch content {
        case .text:
            true

        default:
            false
        }
    }

    /// An element name, if this node is an element node; otherwise, `nil`.
    public var name: String? {
        switch content {
        case let .element(elem, _, _):
            elem.name

        default:
            nil
        }
    }

    /// The target of the processing instruction, if this node is a processing
    /// instruction node; otherwise, `nil`.
    public var target: String? {
        switch content {
        case let .processingInstruction(target, _):
            target

        default:
            nil
        }
    }

    /// A namespace URI, if this node is an element node; otherwise, `nil`.
    public var uri: String? {
        switch content {
        case let .element(elem, _, _):
            elem.uri

        default:
            nil
        }
    }

    /// The concatenation of the string values of all descendant text nodes of
    /// this node, or the string value itself, if this node is a text node;
    /// otherwise, `nil`.
    ///
    /// Comment and processing instruction nodes are not character data, so they
    /// have no value at all — and a comment among an element’s children does
    /// not alter that element’s value. An element node, by contrast, always has
    /// a value: an element with no character data among its descendants has an
    /// empty one, which is why `nil` distinguishes a node that cannot have a
    /// value from one that merely has nothing to say.
    public var value: String? {
        switch content {
        case let .element(_, _, kids):
            Self._valueOfChildElements(kids)

        case let .text(value):
            value

        default:
            nil
        }
    }

    // MARK: Public Instance Methods

    /// Returns an array of all child element nodes of this node.
    ///
    /// - Returns:  An array of all child element nodes. If this node is not an
    ///             element node, this method returns an empty array.
    public func allChildElements() -> [Self] {
        children?.filter { $0.isElement } ?? []
    }

    /// Returns an array of all child element nodes of this node matching the
    /// provided ``XMLElement`` instance.
    ///
    /// - Parameter elem:   An ``XMLElement`` instance to match.
    ///
    /// - Returns:  An array of all matching child element nodes. If this node
    ///             is not an element node, or if there are no matches, this
    ///             method returns an empty array.
    public func allChildElements(_ elem: E) -> [Self] {
        allChildElements([elem])
    }

    /// Returns an array of all child element nodes of this node matching any of
    /// the provided ``XMLElement`` instances.
    ///
    /// - Parameter elems:  An array of ``XMLElement`` instances to match.
    ///
    /// - Returns:  An array of all matching child element nodes. If this node
    ///             is not an element node, or if there are no matches, this
    ///             method returns an empty array.
    public func allChildElements(_ elems: [E]) -> [Self] {
        children?.filter { $0.isElement(elems) } ?? []
    }

    /// Returns the first child element node of this node matching the provided
    /// ``XMLElement`` instance.
    ///
    /// - Parameter elem:   An ``XMLElement`` instance to match.
    ///
    /// - Returns:  The first matching child element node. If this node is not
    ///             an element node, or if there are no matches, this method
    ///             returns `nil`.
    public func firstChildElement(_ elem: E) -> Self? {
        firstChildElement([elem])
    }

    /// Returns the first child element node of this node matching any of the
    /// provided ``XMLElement`` instances.
    ///
    /// - Parameter elems:  An array of ``XMLElement`` instances to match.
    ///
    /// - Returns:  The first matching child element node. If this node is not
    ///             an element node, or if there are no matches, this method
    ///             returns `nil`.
    public func firstChildElement(_ elems: [E]) -> Self? {
        children?.first { $0.isElement(elems) }
    }

    /// Returns a Boolean value indicating whether this node is an element node
    /// matching the provided ``XMLElement`` instance.
    ///
    /// - Parameter elem:   An ``XMLElement`` instance to match.
    ///
    /// - Returns:  `true` if this node is a matching element node; otherwise,
    ///             `false`.
    public func isElement(_ elem: E) -> Bool {
        isElement([elem])
    }

    /// Returns a Boolean value indicating whether this node is an element node
    /// matching any of the provided ``XMLElement`` instances.
    ///
    /// - Parameter elems:  An array of ``XMLElement`` instances to match.
    ///
    /// - Returns:  `true` if this node is a matching element node; otherwise,
    ///             `false`.
    public func isElement(_ elems: [E]) -> Bool {
        switch content {
        case let .element(candElem, _, _):
            elems.contains(candElem)

        default:
            false
        }
    }

    // MARK: Private Type Methods

    private static func _valueOfChildElements(_ children: [Self]) -> String {
        children.reduce(into: "") { result, node in
            switch node.content {
            case let .element(_, _, kids):
                result += _valueOfChildElements(kids)

            case let .text(value):
                result += value

            default:
                break
            }
        }
    }
}

// MARK: - CustomStringConvertible

extension XMLNode: CustomStringConvertible {
    public var description: String {
        switch content {
        case let .comment(text):
            return "<!--\(text)-->"

        case let .element(elem, attrs, kids):
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

        case let .processingInstruction(target, data):
            if let data {
                return "<?\(target) \(data)?>"
            } else {
                return "<?\(target)?>"
            }

        case let .text(value):
            return "\"\(value)\""
        }
    }
}

// MARK: - Sendable

extension XMLNode: Sendable {
}
