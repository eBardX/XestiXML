// © 2022–2025 John Gary Pusey (see LICENSE.md)

public struct XMLNode<E: XMLElement,
                      A: XMLAttribute> {

    // MARK: Public Initializers

    public init(attribute: A,
                value: String) {
        self.content = .attr(attribute, value)
    }

    public init(element: E,
                children: [Self]) {
        self.content = .elem(element, children)
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

    public var attribute: A? {
        switch content {
        case let .attr(attr, _):
            attr

        default:
            nil
        }
    }

    public var children: [Self]? {
        switch content {
        case let .elem(_, children):
            children

        default:
            nil
        }
    }

    public var element: E? {
        switch content {
        case let .elem(elem, _):
            elem

        default:
            nil
        }
    }

    public var isAttribute: Bool {
        switch content {
        case .attr:
            true

        default:
            false
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
        case let .attr(attr, _):
            attr.name

        case let .elem(elem, _):
            elem.name

        default:
            nil
        }
    }

    public var uri: String? {
        switch content {
        case let .elem(elem, _):
            elem.uri

        default:
            nil
        }
    }

    public var value: String? {
        switch content {
        case let .attr(_, value),
            let .text(value):
            value

        case .elem:
            _valueOfElement()
        }
    }

    // MARK: Public Instance Methods

    public func allAttributes() -> [Self] {
        children?.filter { $0.isAttribute } ?? []
    }

    public func allAttributes(_ attr: A) -> [Self] {
        allAttributes([attr])
    }

    public func allAttributes(_ attrs: [A]) -> [Self] {
        children?.filter { $0.isAttribute(attrs) } ?? []
    }

    public func allChildElements() -> [Self] {
        children?.filter { $0.isElement } ?? []
    }

    public func allChildElements(_ elem: E) -> [Self] {
        allChildElements([elem])
    }

    public func allChildElements(_ elems: [E]) -> [Self] {
        children?.filter { $0.isElement(elems) } ?? []
    }

    public func firstAttribute(_ attr: A) -> Self? {
        firstAttribute([attr])
    }

    public func firstAttribute(_ attrs: [A]) -> Self? {
        children?.first { $0.isAttribute(attrs) }
    }

    public func firstChildElement(_ elem: E) -> Self? {
        firstChildElement([elem])
    }

    public func firstChildElement(_ elems: [E]) -> Self? {
        children?.first { $0.isElement(elems) }
    }

    public func isAttribute(_ attr: A) -> Bool {
        isAttribute([attr])
    }

    public func isAttribute(_ attrs: [A]) -> Bool {
        switch content {
        case let .attr(candAttr, _):
            return attrs.contains(candAttr)

        default:
            return false
        }
    }

    public func isElement(_ elem: E) -> Bool {
        isElement([elem])
    }

    public func isElement(_ elems: [E]) -> Bool {
        switch content {
        case let .elem(candElem, _):
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

// MARK: - Sendable

extension XMLNode: Sendable {
}
