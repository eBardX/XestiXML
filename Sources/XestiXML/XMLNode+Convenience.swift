// © 2022–2026 John Gary Pusey (see LICENSE.md)

extension XMLNode {

    // MARK: Public Instance Methods

    /// Checks that this instance is an element node matching the provided
    /// ``XMLElement`` instance.
    ///
    /// - Parameter elem:   An ``XMLElement`` instance to match.
    ///
    /// - Throws:   `XMLError` if this instance is not a matching element node.
    public func expectElement(_ elem: E) throws {
        try expectElement([elem])
    }

    /// Checks that this instance is an element node matching any of the provided
    /// ``XMLElement`` instances.
    ///
    /// - Parameter elems:  An array of ``XMLElement`` instances to match.
    ///
    /// - Throws:   `XMLError` if this instance is not a matching element node.
    public func expectElement(_ elems: [E]) throws {
        guard isElement(elems)
        else { throw try XMLError.unexpectedElement(_requireName(),
                                                    elems.map { $0.name }) }
    }

    /// Returns a Boolean value indicating whether there is a child element node
    /// of this instance matching the provided ``XMLElement`` instance.
    ///
    /// - Parameter elem:   An ``XMLElement`` instance to match.
    ///
    /// - Returns:  `true` if there is a matching child element node. If this
    ///             instance is not an element node, or if there are no matches,
    ///             this method returns `false`.
    public func hasChildElement(_ elem: E) -> Bool {
        hasChildElement([elem])
    }

    /// Returns a Boolean value indicating whether there is a child element node
    /// of this instance matching any of the provided ``XMLElement`` instances.
    ///
    /// - Parameter elems:  An array of ``XMLElement`` instances to match.
    ///
    /// - Returns:  `true` if there is a matching child element node. If this
    ///             instance is not an element node, or if there are no matches,
    ///             this method returns `false`.
    public func hasChildElement(_ elems: [E]) -> Bool {
        firstChildElement(elems) != nil
    }

    /// Returns the first transformed child element node of this instance
    /// matching the provided ``XMLElement`` instance.
    ///
    /// - Parameter elem:       An ``XMLElement`` instance to match.
    /// - Parameter transform:  A mapping closure. `transform` accepts a node as
    ///                         its parameter and returns a transformed value of
    ///                         the same or of a different type.
    ///
    /// - Returns:  The first matching child element node as transformed by
    ///             `transform`. If this instance is not an element node, or if
    ///             there are no matches, this method returns `nil`.
    ///
    /// - Throws:   Any error thrown by `transform`.
    public func optionalChildElement<T>(_ elem: E,
                                        _ transform: (XMLNode<E, A>) throws -> T) throws -> T? {
        try optionalChildElement([elem], transform)
    }

    /// Returns the first transformed child element node of this instance
    /// matching any of the provided ``XMLElement`` instances.
    ///
    /// - Parameter elems:      An array of ``XMLElement`` instances to match.
    /// - Parameter transform:  A mapping closure. `transform` accepts a node as
    ///                         its parameter and returns a transformed value of
    ///                         the same or of a different type.
    ///
    /// - Returns:  The first matching child element node as transformed by
    ///             `transform`. If this instance is not an element node, or if
    ///             there are no matches, this method returns `nil`.
    ///
    /// - Throws:   Any error thrown by `transform`.
    public func optionalChildElement<T>(_ elems: [E],
                                        _ transform: (XMLNode<E, A>) throws -> T) throws -> T? {
        guard let node = firstChildElement(elems)
        else { return nil }

        return try transform(node)
    }

    /// Returns an array of all transformed child element nodes of this instance
    /// matching the provided ``XMLElement`` instance.
    ///
    /// - Parameter elem:       An ``XMLElement`` instance to match.
    /// - Parameter transform:  A mapping closure. `transform` accepts a node as
    ///                         its parameter and returns a transformed value of
    ///                         the same or of a different type.
    ///
    /// - Returns:  An array of all matching child element nodes as transformed
    ///             by `transform`. If this instance is not an element node, or
    ///             if there are no matches, this method returns an empty array.
    ///
    /// - Throws:   Any error thrown by `transform`.
    public func optionalChildElements<T>(_ elem: E,
                                         _ transform: (XMLNode<E, A>) throws -> T) throws -> [T] {
        try optionalChildElements([elem], transform)
    }

    /// Returns an array of all transformed child element nodes of this instance
    /// matching any of the provided ``XMLElement`` instances.
    ///
    /// - Parameter elems:      An array of ``XMLElement`` instances to match.
    /// - Parameter transform:  A mapping closure. `transform` accepts a node as
    ///                         its parameter and returns a transformed value of
    ///                         the same or of a different type.
    ///
    /// - Returns:  An array of all matching child element nodes as transformed
    ///             by `transform`. If this instance is not an element node, or
    ///             if there are no matches, this method returns an empty array.
    ///
    /// - Throws:   Any error thrown by `transform`.
    public func optionalChildElements<T>(_ elems: [E],
                                         _ transform: (XMLNode<E, A>) throws -> T) throws -> [T] {
        let nodes = allChildElements(elems)

        guard !nodes.isEmpty
        else { return [] }

        return try nodes.map { try transform($0) }
    }

    /// Returns the first transformed child element node of this instance
    /// matching the provided ``XMLElement`` instance.
    ///
    /// - Parameter elem:       An ``XMLElement`` instance to match.
    /// - Parameter transform:  A mapping closure. `transform` accepts a node as
    ///                         its parameter and returns a transformed value of
    ///                         the same or of a different type.
    ///
    /// - Returns:  The first matching child element node as transformed by
    ///             `transform`.
    ///
    /// - Throws:   `XMLError.missingRequiredChildElement` if this instance is
    ///             not an element node, or if there are no matches. Any error
    ///             thrown by `transform`.
    public func requiredChildElement<T>(_ elem: E,
                                        _ transform: (XMLNode<E, A>) throws -> T) throws -> T {
        try requiredChildElement([elem], transform)
    }

    /// Returns the first transformed child element node of this instance
    /// matching any of the provided ``XMLElement`` instances.
    ///
    /// - Parameter elems:      An array of ``XMLElement`` instances to match.
    /// - Parameter transform:  A mapping closure. `transform` accepts a node as
    ///                         its parameter and returns a transformed value of
    ///                         the same or of a different type.
    ///
    /// - Returns:  The first matching child element node as transformed by
    ///             `transform`.
    ///
    /// - Throws:   `XMLError.missingRequiredChildElement` if this instance is
    ///             not an element node, or if there are no matches. Any error
    ///             thrown by `transform`.
    public func requiredChildElement<T>(_ elems: [E],
                                        _ transform: (XMLNode<E, A>) throws -> T) throws -> T {
        guard let node = firstChildElement(elems)
        else { throw try XMLError.missingRequiredChildElement(_requireName(),
                                                              elems.map { $0.name }) }

        return try transform(node)
    }

    /// Returns an array of all transformed child element nodes of this instance
    /// matching the provided ``XMLElement`` instance.
    ///
    /// - Parameter elem:       An ``XMLElement`` instance to match.
    /// - Parameter transform:  A mapping closure. `transform` accepts a node as
    ///                         its parameter and returns a transformed value of
    ///                         the same or of a different type.
    ///
    /// - Returns:  An array of all matching child element nodes as transformed
    ///             by `transform`.
    ///
    /// - Throws:   `XMLError.missingRequiredChildElement` if this instance is
    ///             not an element node, or if there are no matches. Any error
    ///             thrown by `transform`.
    public func requiredChildElements<T>(_ elem: E,
                                         _ transform: (XMLNode<E, A>) throws -> T) throws -> [T] {
        try requiredChildElements([elem], transform)
    }

    /// Returns an array of all transformed child element nodes of this instance
    /// matching any of the provided ``XMLElement`` instances.
    ///
    /// - Parameter elems:      An array of ``XMLElement`` instances to match.
    /// - Parameter transform:  A mapping closure. `transform` accepts a node as
    ///                         its parameter and returns a transformed value of
    ///                         the same or of a different type.
    ///
    /// - Returns:  An array of all matching child element nodes as transformed
    ///             by `transform`.
    ///
    /// - Throws:   `XMLError.missingRequiredChildElement` if this instance is
    ///             not an element node, or if there are no matches. Any error
    ///             thrown by `transform`.
    public func requiredChildElements<T>(_ elems: [E],
                                         _ transform: (XMLNode<E, A>) throws -> T) throws -> [T] {
        let nodes = allChildElements(elems)

        guard !nodes.isEmpty
        else { throw try XMLError.missingRequiredChildElement(_requireName(),
                                                              elems.map { $0.name }) }

        return try nodes.map { try transform($0) }
    }

    /// Convenience method that complains that this instance is an unexpected
    /// root element.
    ///
    /// - Throws:   `XMLError.unexpectedRootElement` always.
    public func unexpectedRootElement() throws {
        throw try XMLError.unexpectedRootElement(_requireName())
    }

    /// Convenience method that complains that this instance is an unsupported
    /// root element.
    ///
    /// - Throws:   `XMLError.unsupportedRootElement` always.
    public func unsupportedRootElement() throws {
        throw try XMLError.unsupportedRootElement(_requireName())
    }

    /// Returns the transformed value of the first attribute node of this
    /// instance matching the provided ``XMLAttribute`` instance.
    ///
    /// - Parameter attr:       An ``XMLAttribute`` instance to match.
    /// - Parameter validate:   A validation closure. `validate` accepts a
    ///                         string value as its parameter and optionally
    ///                         returns a transformed value of the same or of a
    ///                         different type. If `validate` returns `nil`, the
    ///                         string value is considered to be invalid. By
    ///                         default, returns the value untransformed.
    ///
    /// - Returns:  The value of the first matching attribute node as
    ///             transformed by `validate`. If this instance is not an
    ///             element node, or if there are no matches, this method
    ///             returns `nil`.
    ///
    /// - Throws:   `XMLError.invalidAttributeValue` if the attribute value is
    ///             invalid according to `validate`.
    public func valueOfOptionalAttribute<T>(_ attr: A,
                                            _ validate: (String) -> T? = { $0 }) throws -> T? {
        try valueOfOptionalAttribute([attr], validate)
    }

    /// Returns the transformed value of the first attribute node of this
    /// instance matching any of the provided ``XMLAttribute`` instances.
    ///
    /// - Parameter attrs:      An array of ``XMLAttribute`` instances to match.
    /// - Parameter validate:   A validation closure. `validate` accepts a
    ///                         string value as its parameter and optionally
    ///                         returns a transformed value of the same or of a
    ///                         different type. If `validate` returns `nil`, the
    ///                         string value is considered to be invalid. By
    ///                         default, returns the value untransformed.
    ///
    /// - Returns:  The value of the first matching attribute node as
    ///             transformed by `validate`. If this instance is not an
    ///             element node, or if there are no matches, this method
    ///             returns `nil`.
    ///
    /// - Throws:   `XMLError.invalidAttributeValue` if the attribute value is
    ///             invalid according to `validate`.
    public func valueOfOptionalAttribute<T>(_ attrs: [A],
                                            _ validate: (String) -> T? = { $0 }) throws -> T? {
        guard let attributes,
              let attrValue = _firstAttribute(attrs, attributes)
        else { return nil }

        let (value, strValue, isValid) = _validateValue(attrValue, validate)

        guard isValid, let value
        else { throw XMLError.invalidAttributeValue(attrs.map { $0.name }, strValue) }

        return value
    }

    /// Returns the transformed ``value`` of the first child element node of
    /// this instance matching the provided ``XMLElement`` instance.
    ///
    /// - Parameter elem:       An ``XMLElement`` instance to match.
    /// - Parameter validate:   A validation closure. `validate` accepts a
    ///                         string value as its parameter and optionally
    ///                         returns a transformed value of the same or of a
    ///                         different type. If `validate` returns `nil`, the
    ///                         string value is considered to be invalid. By
    ///                         default, returns the value untransformed.
    ///
    /// - Returns:  The ``value`` of the first matching child element node as
    ///             transformed by `validate`. If this instance is not an
    ///             element node, or if there are no matches, this method
    ///             returns `nil`.
    ///
    /// - Throws:   `XMLError.invalidElementValue` if the element value is
    ///             invalid according to `validate`.
    public func valueOfOptionalChildElement<T>(_ elem: E,
                                               _ validate: (String) -> T? = { $0 }) throws -> T? {
        try valueOfOptionalChildElement([elem], validate)
    }

    /// Returns the transformed ``value`` of the first child element node of
    /// this instance matching any of the provided ``XMLElement`` instances.
    ///
    /// - Parameter elems:      An array of ``XMLElement`` instances to match.
    /// - Parameter validate:   A validation closure. `validate` accepts a
    ///                         string value as its parameter and optionally
    ///                         returns a transformed value of the same or of a
    ///                         different type. If `validate` returns `nil`, the
    ///                         string value is considered to be invalid. By
    ///                         default, returns the value untransformed.
    ///
    /// - Returns:  The ``value`` of the first matching child element node as
    ///             transformed by `validate`. If this instance is not an
    ///             element node, or if there are no matches, this method
    ///             returns `nil`.
    ///
    /// - Throws:   `XMLError.invalidElementValue` if the element value is
    ///             invalid according to `validate`.
    public func valueOfOptionalChildElement<T>(_ elems: [E],
                                               _ validate: (String) -> T? = { $0 }) throws -> T? {
        guard let node = firstChildElement(elems)
        else { return nil }

        let (value, strValue, isValid) = _validateValue(node.value, validate)

        guard isValid, let value
        else { throw XMLError.invalidElementValue(elems.map { $0.name }, strValue) }

        return value
    }

    /// Returns the transformed value of the first attribute node of this
    /// instance matching the provided ``XMLAttribute`` instance.
    ///
    /// - Parameter attr:       An ``XMLAttribute`` instance to match.
    /// - Parameter validate:   A validation closure. `validate` accepts a
    ///                         string value as its parameter and optionally
    ///                         returns a transformed value of the same or of a
    ///                         different type. If `validate` returns `nil`, the
    ///                         string value is considered to be invalid. By
    ///                         default, returns the value untransformed.
    ///
    /// - Returns:  The value of the first matching attribute node as
    ///             transformed by `validate`.
    ///
    /// - Throws:   `XMLError.missingRequiredAttribute` if this instance is not
    ///             an element node, or if there are no matches.
    ///             `XMLError.invalidAttributeValue` if the attribute value is
    ///             invalid according to `validate`.
    public func valueOfRequiredAttribute<T>(_ attr: A,
                                            _ validate: (String) -> T? = { $0 }) throws -> T {
        try valueOfRequiredAttribute([attr], validate)
    }

    /// Returns the transformed value of the first attribute node of this
    /// instance matching any of the provided ``XMLAttribute`` instances.
    ///
    /// - Parameter attrs:      An array of ``XMLAttribute`` instances to match.
    /// - Parameter validate:   A validation closure. `validate` accepts a
    ///                         string value as its parameter and optionally
    ///                         returns a transformed value of the same or of a
    ///                         different type. If `validate` returns `nil`, the
    ///                         string value is considered to be invalid. By
    ///                         default, returns the value untransformed.
    ///
    /// - Returns:  The value of the first matching attribute node as
    ///             transformed by `validate`.
    ///
    /// - Throws:   `XMLError.missingRequiredAttribute` if this instance is not
    ///             an element node, or if there are no matches.
    ///             `XMLError.invalidAttributeValue` if the attribute value is
    ///             invalid according to `validate`.
    public func valueOfRequiredAttribute<T>(_ attrs: [A],
                                            _ validate: (String) -> T? = { $0 }) throws -> T {
        guard let attributes,
              let attrValue = _firstAttribute(attrs, attributes)
        else { throw try XMLError.missingRequiredAttribute(_requireName(), attrs.map { $0.name }) }

        let (value, strValue, isValid) = _validateValue(attrValue, validate)

        guard isValid, let value
        else { throw XMLError.invalidAttributeValue(attrs.map { $0.name }, strValue) }

        return value
    }

    /// Returns the transformed ``value`` of the first child element node of
    /// this instance matching the provided ``XMLElement`` instance.
    ///
    /// - Parameter elem:       An ``XMLElement`` instance to match.
    /// - Parameter validate:   A validation closure. `validate` accepts a
    ///                         string value as its parameter and optionally
    ///                         returns a transformed value of the same or of a
    ///                         different type. If `validate` returns `nil`, the
    ///                         string value is considered to be invalid. By
    ///                         default, returns the value untransformed.
    ///
    /// - Returns:  The ``value`` of the first matching child element node as
    ///             transformed by `validate`.
    ///
    /// - Throws:   `XMLError.missingRequiredChildElement` if this instance is
    ///             not an element node, or if there are no matches.
    ///             `XMLError.invalidElementValue` if the element value is
    ///             invalid according to `validate`.
    public func valueOfRequiredChildElement<T>(_ elem: E,
                                               _ validate: (String) -> T? = { $0 }) throws -> T {
        try valueOfRequiredChildElement([elem], validate)
    }

    /// Returns the transformed ``value`` of the first child element node of
    /// this instance matching any of the provided ``XMLElement`` instances.
    ///
    /// - Parameter elems:      An array of ``XMLElement`` instances to match.
    /// - Parameter validate:   A validation closure. `validate` accepts a
    ///                         string value as its parameter and optionally
    ///                         returns a transformed value of the same or of a
    ///                         different type. If `validate` returns `nil`, the
    ///                         string value is considered to be invalid. By
    ///                         default, returns the value untransformed.
    ///
    /// - Returns:  The ``value`` of the first matching child element node as
    ///             transformed by `validate`.
    ///
    /// - Throws:   `XMLError.missingRequiredChildElement` if this instance is
    ///             not an element node, or if there are no matches.
    ///             `XMLError.invalidElementValue` if the element value is
    ///             invalid according to `validate`.
    public func valueOfRequiredChildElement<T>(_ elems: [E],
                                               _ validate: (String) -> T? = { $0 }) throws -> T {
        guard let node = firstChildElement(elems)
        else { throw try XMLError.missingRequiredChildElement(_requireName(), elems.map { $0.name }) }

        let (value, strValue, isValid) = _validateValue(node.value, validate)

        guard isValid, let value
        else { throw XMLError.invalidElementValue(elems.map { $0.name }, strValue) }

        return value
    }

    // MARK: Private Instance Methods

    private func _requireName() throws -> String {
        guard let name
        else { throw XMLError.internalFailure }

        return name
    }
}

// MARK: Private Functions

private func _firstAttribute<A: XMLAttribute>(_ attrs: [A],
                                              _ attributes: [A: String]) -> String? {
    for attr in attrs {
        if let value = attributes[attr] {
            return value
        }
    }

    return nil
}

private func _validateValue<T>(_ value: String?,
                               _ validate: (String) -> T?) -> (T?, String, Bool) {
    let strValue = value?.normalizedXMLWhitespace() ?? ""

    guard let value = validate(strValue)
    else { return (nil, strValue, false) }

    return (value, strValue, true)
}
