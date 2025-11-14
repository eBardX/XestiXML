// © 2022–2025 John Gary Pusey (see LICENSE.md)

extension XMLNode {

    // MARK: Public Instance Methods

    public func expectElement(_ elem: E) throws {
        try expectElement([elem])
    }

    public func expectElement(_ elems: [E]) throws {
        guard isElement(elems)
        else { throw XMLError.unexpectedElement(element.require().name, elems.map { $0.name }) }
    }

    public func hasChildElement(_ elem: E) -> Bool {
        hasChildElement([elem])
    }

    public func hasChildElement(_ elems: [E]) -> Bool {
        firstChildElement(elems) != nil
    }

    public func optionalChildElement<T>(_ elem: E,
                                        _ transform: (XMLNode<E, A>) throws -> T) throws -> T? {
        try optionalChildElement([elem], transform)
    }

    public func optionalChildElement<T>(_ elems: [E],
                                        _ transform: (XMLNode<E, A>) throws -> T) throws -> T? {
        guard let node = firstChildElement(elems)
        else { return nil }

        return try transform(node)
    }

    public func optionalChildElements<T>(_ elem: E,
                                         _ transform: (XMLNode<E, A>) throws -> T) throws -> [T] {
        try optionalChildElements([elem], transform)
    }

    public func optionalChildElements<T>(_ elems: [E],
                                         _ transform: (XMLNode<E, A>) throws -> T) throws -> [T] {
        let nodes = allChildElements(elems)

        guard !nodes.isEmpty
        else { return [] }

        return try nodes.map { try transform($0) }
    }

    public func requiredChildElement<T>(_ elem: E,
                                        _ transform: (XMLNode<E, A>) throws -> T) throws -> T {
        try requiredChildElement([elem], transform)
    }

    public func requiredChildElement<T>(_ elems: [E],
                                        _ transform: (XMLNode<E, A>) throws -> T) throws -> T {
        guard let node = firstChildElement(elems)
        else { throw XMLError.missingRequiredChildElement(element.require().name, elems.map { $0.name }) }

        return try transform(node)
    }

    public func requiredChildElements<T>(_ elem: E,
                                         _ transform: (XMLNode<E, A>) throws -> T) throws -> [T] {
        try requiredChildElements([elem], transform)
    }

    public func requiredChildElements<T>(_ elems: [E],
                                         _ transform: (XMLNode<E, A>) throws -> T) throws -> [T] {
        let nodes = allChildElements(elems)

        guard !nodes.isEmpty
        else { throw XMLError.missingRequiredChildElement(element.require().name, elems.map { $0.name }) }

        return try nodes.map { try transform($0) }
    }

    public func unexpectedRootElement() throws {
       throw XMLError.unexpectedRootElement(element.require().name)
    }

    public func unsupportedRootElement() throws {
       throw XMLError.unsupportedRootElement(element.require().name)
    }

    public func valueOfExpectedElement<T>(_ elem: E,
                                          _ validate: (String) -> T? = { $0 }) throws -> T {
        try valueOfExpectedElement([elem], validate)
    }

    public func valueOfExpectedElement<T>(_ elems: [E],
                                          _ validate: (String) -> T? = { $0 }) throws -> T {
        try expectElement(elems)

        let (value, strValue, isValid) = _valueOfNode(validate)

        guard isValid, let value
        else { throw XMLError.invalidElementValue(elems.map { $0.name }, strValue) }

        return value
    }

    public func valueOfOptionalAttribute<T>(_ attr: A,
                                            _ validate: (String) -> T? = { $0 }) throws -> T? {
        try valueOfOptionalAttribute([attr], validate)
    }

    public func valueOfOptionalAttribute<T>(_ attrs: [A],
                                            _ validate: (String) -> T? = { $0 }) throws -> T? {
        guard let node = firstAttribute(attrs)
        else { return nil }

        let (value, strValue, isValid) = node._valueOfNode(validate)

        guard isValid, let value
        else { throw XMLError.invalidAttributeValue(attrs.map { $0.name }, strValue) }

        return value
    }

    public func valueOfOptionalChildElement<T>(_ elem: E,
                                               _ validate: (String) -> T? = { $0 }) throws -> T? {
        try valueOfOptionalChildElement([elem], validate)
    }

    public func valueOfOptionalChildElement<T>(_ elems: [E],
                                               _ validate: (String) -> T? = { $0 }) throws -> T? {
        guard let node = firstChildElement(elems)
        else { return nil }

        let (value, strValue, isValid) = node._valueOfNode(validate)

        guard isValid, let value
        else { throw XMLError.invalidElementValue(elems.map { $0.name }, strValue) }

        return value
    }

    public func valueOfRequiredAttribute<T>(_ attr: A,
                                            _ validate: (String) -> T? = { $0 }) throws -> T {
        try valueOfRequiredAttribute([attr], validate)
    }

    public func valueOfRequiredAttribute<T>(_ attrs: [A],
                                            _ validate: (String) -> T? = { $0 }) throws -> T {
        guard let node = firstAttribute(attrs)
        else { throw XMLError.missingRequiredAttribute(element.require().name, attrs.map { $0.name }) }

        let (value, strValue, isValid) = node._valueOfNode(validate)

        guard isValid, let value
        else { throw XMLError.invalidAttributeValue(attrs.map { $0.name }, strValue) }

        return value
    }

    public func valueOfRequiredChildElement<T>(_ elem: E,
                                               _ validate: (String) -> T? = { $0 }) throws -> T {
        try valueOfRequiredChildElement([elem], validate)
    }

    public func valueOfRequiredChildElement<T>(_ elems: [E],
                                               _ validate: (String) -> T? = { $0 }) throws -> T {
        guard let node = firstChildElement(elems)
        else { throw XMLError.missingRequiredChildElement(element.require().name, elems.map { $0.name }) }

        let (value, strValue, isValid) = node._valueOfNode(validate)

        guard isValid, let value
        else { throw XMLError.invalidElementValue(elems.map { $0.name }, strValue) }

        return value
    }

    // MARK: Private Instance Methods

    private func _valueOfNode<T>(_ validate: (String) -> T?) -> (T?, String, Bool) {
        let strValue = value?.normalizedXMLWhitespace() ?? ""

        guard let value = validate(strValue)
        else { return (nil, strValue, false) }

        return (value, strValue, true)
    }
}
