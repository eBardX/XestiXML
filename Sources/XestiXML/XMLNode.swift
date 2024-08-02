// © 2022–2024 John Gary Pusey (see LICENSE.md)

public enum XMLNode<E: XMLElement, A: XMLAttribute> {
    case attr(A, String)
    case elem(E, [Self])
    case text(String)
}

// MARK: -

extension XMLNode {

    // MARK: Public Instance Properties

    public var attribute: A? {
        switch self {
        case let .attr(attr, _):
            attr

        default:
            nil
        }
    }

    public var children: [Self]? {
        switch self {
        case let .elem(_, children):
            children

        default:
            nil
        }
    }

    public var element: E? {
        switch self {
        case let .elem(elem, _):
            elem

        default:
            nil
        }
    }

    public var isAttribute: Bool {
        switch self {
        case .attr:
            true

        default:
            false
        }
    }

    public var isElement: Bool {
        switch self {
        case .elem:
            true

        default:
            false
        }
    }

    public var isText: Bool {
        switch self {
        case .text:
            true

        default:
            false
        }
    }

    public var name: String? {
        switch self {
        case let .attr(attr, _):
            attr.name

        case let .elem(elem, _):
            elem.name

        default:
            nil
        }
    }

    public var uri: String? {
        switch self {
        case let .elem(elem, _):
            elem.uri

        default:
            nil
        }
    }

    public var value: String? {
        switch self {
        case let .attr(_, value),
            let .text(value):
            value

        default:
            nil
        }
    }

    // MARK: Public Instance Methods

    public func allAttributes() -> [Self] {
        children?.filter { $0.isAttribute } ?? []
    }

    public func allChildElements() -> [Self] {
        children?.filter { $0.isElement } ?? []
    }

    public func allChildElements(_ elem: E) -> [Self] {
        children?.filter { $0.isElement(elem) } ?? []
    }

    public func firstAttribute(_ attr: A) -> Self? {
        children?.first { $0.isAttribute(attr) }
    }

    public func firstChildElement(_ elem: E) -> Self? {
        children?.first { $0.isElement(elem) }
    }

    public func isAttribute(_ attr: A) -> Bool {
        switch self {
        case let .attr(candAttr, _):
            return candAttr == attr

        default:
            return false
        }
    }

    public func isElement(_ elem: E) -> Bool {
        switch self {
        case let .elem(candElem, _):
            return candElem == elem

        default:
            return false
        }
    }
}

// MARK: - CustomStringConvertible

extension XMLNode: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .attr(attr, value):
            "\(attr.name)=\"\(value)\""

        case let .elem(elem, children):
            if children.isEmpty {
                "<\(elem.name)>"
            } else {
                "<\(elem.name)>\(children)"
            }

        case let .text(value):
            "\"\(value)\""
        }
    }
}
