// © 2022–2026 John Gary Pusey (see LICENSE.md)

public struct XMLNode<E: XMLElement, A: XMLAttribute> {

    // MARK: Public Initializers

    public init(element: E,
                attributes: [A: String],
                children: [Self]) {
        self.content = .elem(element, attributes, children)
    }

    public init(text: String) {
        self.content = .text(text)
    }

    // MARK: Internal Instance Properties

    internal let content: Content
}

// MARK: -

extension XMLNode {

    // MARK: Public Instance Properties

    public var attributes: [A: String]? {
        switch content {
        case let .elem(_, attrs, _):
            attrs

        default:
            nil
        }
    }

    public var children: [Self]? {
        switch content {
        case let .elem(_, _, kids):
            kids

        default:
            nil
        }
    }

    public var element: E? {
        switch content {
        case let .elem(elem, _, _):
            elem

        default:
            nil
        }
    }

    public var isElement: Bool {
        switch content {
        case .elem:
            true

        default:
            false
        }
    }

    public var isText: Bool {
        switch content {
        case .text:
            true

        default:
            false
        }
    }

    public var name: String? {
        switch content {
        case let .elem(elem, _, _):
            elem.name

        default:
            nil
        }
    }

    public var uri: String? {
        switch content {
        case let .elem(elem, _, _):
            elem.uri

        default:
            nil
        }
    }

    public var value: String? {
        switch content {
        case .elem:
            _valueOfElement()

        case let .text(value):
            value
        }
    }

    // MARK: Public Instance Methods

    public func allChildElements() -> [Self] {
        children?.filter { $0.isElement } ?? []
    }

    public func allChildElements(_ elem: E) -> [Self] {
        allChildElements([elem])
    }

    public func allChildElements(_ elems: [E]) -> [Self] {
        children?.filter { $0.isElement(elems) } ?? []
    }

    public func firstChildElement(_ elem: E) -> Self? {
        firstChildElement([elem])
    }

    public func firstChildElement(_ elems: [E]) -> Self? {
        children?.first { $0.isElement(elems) }
    }

    public func isElement(_ elem: E) -> Bool {
        isElement([elem])
    }

    public func isElement(_ elems: [E]) -> Bool {
        switch content {
        case let .elem(candElem, _, _):
            return elems.contains(candElem)

        default:
            return false
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

            for (attr, val) in attrs {
                result += " \(attr.name)=\"\(val)\""
            }

            result += ">"

            if !kids.isEmpty {
                result += "\(kids)"
            }

            return result

        case let .text(value):
            return "\"\(value)\""
        }
    }
}

// MARK: - Sendable

extension XMLNode: Sendable {
}
