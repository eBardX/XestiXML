// © 2022–2026 John Gary Pusey (see LICENSE.md)

extension XMLNode {

    // MARK: Public Instance Methods

    /// Checks that this node is an element node matching the provided
    /// ``XMLElement`` instance.
    ///
    /// - Parameter elem:   An ``XMLElement`` instance to match.
    ///
    /// - Throws:   ``Error`` if this node is not a matching element node.
    public func expectElement(_ elem: E) throws(Error) {
        try expectElement([elem])
    }

    /// Checks that this node is an element node matching any of the provided
    /// ``XMLElement`` instances.
    ///
    /// - Parameter elems:  An array of ``XMLElement`` instances to match.
    ///
    /// - Throws:   ``Error`` if this node is not a matching element node.
    public func expectElement(_ elems: [E]) throws(Error) {
        guard isElement(elems)
        else { throw try Error.unexpectedElement(_requireName(),
                                                 elems.map { $0.name }) }
    }

    /// Returns a Boolean value indicating whether there is a child element node
    /// of this node matching the provided ``XMLElement`` instance.
    ///
    /// - Parameter elem:   An ``XMLElement`` instance to match.
    ///
    /// - Returns:  `true` if there is a matching child element node. If this
    ///             node is not an element node, or if there are no matches,
    ///             this method returns `false`.
    public func hasChildElement(_ elem: E) -> Bool {
        hasChildElement([elem])
    }

    /// Returns a Boolean value indicating whether there is a child element node
    /// of this node matching any of the provided ``XMLElement`` instances.
    ///
    /// - Parameter elems:  An array of ``XMLElement`` instances to match.
    ///
    /// - Returns:  `true` if there is a matching child element node. If this
    ///             node is not an element node, or if there are no matches,
    ///             this method returns `false`.
    public func hasChildElement(_ elems: [E]) -> Bool {
        firstChildElement(elems) != nil
    }

    /// Returns the first transformed child element node of this node matching
    /// the provided ``XMLElement`` instance.
    ///
    /// - Parameter elem:       An ``XMLElement`` instance to match.
    /// - Parameter transform:  A mapping closure. `transform` accepts a node as
    ///                         its parameter and returns a transformed value of
    ///                         the same or of a different type.
    ///
    /// - Returns:  The first matching child element node as transformed by
    ///             `transform`. If this node is not an element node, or if
    ///             there are no matches, this method returns `nil`.
    ///
    /// - Throws:   Any error thrown by `transform`.
    public func optionalChildElement<T>(_ elem: E,
                                        _ transform: (XMLNode<E, A>) throws -> T) throws -> T? {
        try optionalChildElement([elem], transform)
    }

    /// Returns the first transformed child element node of this node matching
    /// any of the provided ``XMLElement`` instances.
    ///
    /// - Parameter elems:      An array of ``XMLElement`` instances to match.
    /// - Parameter transform:  A mapping closure. `transform` accepts a node as
    ///                         its parameter and returns a transformed value of
    ///                         the same or of a different type.
    ///
    /// - Returns:  The first matching child element node as transformed by
    ///             `transform`. If this node is not an element node, or if
    ///             there are no matches, this method returns `nil`.
    ///
    /// - Throws:   Any error thrown by `transform`.
    public func optionalChildElement<T>(_ elems: [E],
                                        _ transform: (XMLNode<E, A>) throws -> T) throws -> T? {
        guard let node = firstChildElement(elems)
        else { return nil }

        return try transform(node)
    }

    /// Returns an array of all transformed child element nodes of this node
    /// matching the provided ``XMLElement`` instance.
    ///
    /// - Parameter elem:       An ``XMLElement`` instance to match.
    /// - Parameter transform:  A mapping closure. `transform` accepts a node as
    ///                         its parameter and returns a transformed value of
    ///                         the same or of a different type.
    ///
    /// - Returns:  An array of all matching child element nodes as transformed
    ///             by `transform`. If this node is not an element node, or if
    ///             there are no matches, this method returns an empty array.
    ///
    /// - Throws:   Any error thrown by `transform`.
    public func optionalChildElements<T>(_ elem: E,
                                         _ transform: (XMLNode<E, A>) throws -> T) throws -> [T] {
        try optionalChildElements([elem], transform)
    }

    /// Returns an array of all transformed child element nodes of this node
    /// matching any of the provided ``XMLElement`` instances.
    ///
    /// - Parameter elems:      An array of ``XMLElement`` instances to match.
    /// - Parameter transform:  A mapping closure. `transform` accepts a node as
    ///                         its parameter and returns a transformed value of
    ///                         the same or of a different type.
    ///
    /// - Returns:  An array of all matching child element nodes as transformed
    ///             by `transform`. If this node is not an element node, or if
    ///             there are no matches, this method returns an empty array.
    ///
    /// - Throws:   Any error thrown by `transform`.
    public func optionalChildElements<T>(_ elems: [E],
                                         _ transform: (XMLNode<E, A>) throws -> T) throws -> [T] {
        let nodes = allChildElements(elems)

        guard !nodes.isEmpty
        else { return [] }

        return try nodes.map { try transform($0) }
    }

    /// Returns the transformed ``value`` of this node.
    ///
    /// - Parameter validate:   A validation closure. `validate` accepts a
    ///                         string value as its parameter and optionally
    ///                         returns a transformed value of the same or of a
    ///                         different type. If `validate` returns `nil`, the
    ///                         string value is considered to be invalid. By
    ///                         default, returns the value untransformed.
    ///
    /// - Returns:  The transformed text value, or `nil` if this node has an
    ///             empty text value.
    ///
    /// - Throws:   `Error.invalidElementValue` if the value is invalid
    ///             according to `validate`.
    public func optionalValue<T>(_ validate: (String) -> T? = { $0 }) throws(Error) -> T? {
        let (outValue, strValue, isValid) = _validateValue(value, validate)

        guard !strValue.isEmpty
        else { return nil }

        guard isValid, let outValue
        else { throw try Error.invalidElementValue([_requireName()], strValue) }

        return outValue
    }

    /// Returns the first transformed child element node of this node matching
    /// the provided ``XMLElement`` instance.
    ///
    /// - Parameter elem:       An ``XMLElement`` instance to match.
    /// - Parameter transform:  A mapping closure. `transform` accepts a node as
    ///                         its parameter and returns a transformed value of
    ///                         the same or of a different type.
    ///
    /// - Returns:  The first matching child element node as transformed by
    ///             `transform`.
    ///
    /// - Throws:   `Error.missingRequiredChildElement` if this node is not an
    ///             element node, or if there are no matches. Any error thrown
    ///             by `transform`.
    public func requiredChildElement<T>(_ elem: E,
                                        _ transform: (XMLNode<E, A>) throws -> T) throws -> T {
        try requiredChildElement([elem], transform)
    }

    /// Returns the first transformed child element node of this node matching
    /// any of the provided ``XMLElement`` instances.
    ///
    /// - Parameter elems:      An array of ``XMLElement`` instances to match.
    /// - Parameter transform:  A mapping closure. `transform` accepts a node as
    ///                         its parameter and returns a transformed value of
    ///                         the same or of a different type.
    ///
    /// - Returns:  The first matching child element node as transformed by
    ///             `transform`.
    ///
    /// - Throws:   `Error.missingRequiredChildElement` if this node is not an
    ///             element node, or if there are no matches. Any error thrown
    ///             by `transform`.
    public func requiredChildElement<T>(_ elems: [E],
                                        _ transform: (XMLNode<E, A>) throws -> T) throws -> T {
        guard let node = firstChildElement(elems)
        else { throw try Error.missingRequiredChildElement(_requireName(),
                                                           elems.map { $0.name }) }

        return try transform(node)
    }

    /// Returns an array of all transformed child element nodes of this node
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
    /// - Throws:   `Error.missingRequiredChildElement` if this node is not an
    ///             element node, or if there are no matches. Any error thrown
    ///             by `transform`.
    public func requiredChildElements<T>(_ elem: E,
                                         _ transform: (XMLNode<E, A>) throws -> T) throws -> [T] {
        try requiredChildElements([elem], transform)
    }

    /// Returns an array of all transformed child element nodes of this node
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
    /// - Throws:   `Error.missingRequiredChildElement` if this node is not an
    ///             element node, or if there are no matches. Any error thrown
    ///             by `transform`.
    public func requiredChildElements<T>(_ elems: [E],
                                         _ transform: (XMLNode<E, A>) throws -> T) throws -> [T] {
        let nodes = allChildElements(elems)

        guard !nodes.isEmpty
        else { throw try Error.missingRequiredChildElement(_requireName(),
                                                           elems.map { $0.name }) }

        return try nodes.map { try transform($0) }
    }

    /// Returns the transformed ``value`` of this node.
    ///
    /// - Parameter validate:   A validation closure. `validate` accepts a
    ///                         string value as its parameter and optionally
    ///                         returns a transformed value of the same or of a
    ///                         different type. If `validate` returns `nil`, the
    ///                         string value is considered to be invalid. By
    ///                         default, returns the value untransformed.
    ///
    /// - Returns:  The transformed text value.
    ///
    /// - Throws:   `Error.invalidElementValue` if this node has an empty text
    ///             value, or the value is invalid according to `validate`.
    public func requiredValue<T>(_ validate: (String) -> T? = { $0 }) throws(Error) -> T {
        let (outValue, strValue, isValid) = _validateValue(value, validate)

        guard isValid, !strValue.isEmpty, let outValue
        else { throw try Error.invalidElementValue([_requireName()], strValue) }

        return outValue
    }

    /// Throws an error indicating that this node is an unexpected element,
    /// given the provided ``XMLElement`` instance that was expected.
    ///
    /// - Parameter elem:   The ``XMLElement`` instance that was expected.
    ///
    /// - Throws:   `Error.unexpectedElement` always.
    public func unexpectedElement(_ elem: E) throws(Error) -> Never {
        try unexpectedElement([elem])
    }

    /// Throws an error indicating that this node is an unexpected element,
    /// given the provided ``XMLElement`` instances that were expected.
    ///
    /// - Parameter elems:  An array of ``XMLElement`` instances that were
    ///                     expected.
    ///
    /// - Throws:   `Error.unexpectedElement` always.
    public func unexpectedElement(_ elems: [E]) throws(Error) -> Never {
        throw try Error.unexpectedElement(_requireName(),
                                          elems.map { $0.name })
    }

    /// Throws an error indicating that this node is an unexpected root element.
    ///
    /// - Throws:   `Error.unexpectedRootElement` always.
    public func unexpectedRootElement() throws(Error) -> Never {
        throw try Error.unexpectedRootElement(_requireName())
    }

    /// Throws an error indicating that this node is an unsupported root
    /// element.
    ///
    /// - Throws:   `Error.unsupportedRootElement` always.
    public func unsupportedRootElement() throws(Error) -> Never {
        throw try Error.unsupportedRootElement(_requireName())
    }

    /// Returns the transformed value of the first attribute of this node
    /// matching the provided ``XMLAttribute`` instance.
    ///
    /// - Parameter attr:       An ``XMLAttribute`` instance to match.
    /// - Parameter validate:   A validation closure. `validate` accepts a
    ///                         string value as its parameter and optionally
    ///                         returns a transformed value of the same or of a
    ///                         different type. If `validate` returns `nil`, the
    ///                         string value is considered to be invalid. By
    ///                         default, returns the value untransformed.
    ///
    /// - Returns:  The value of the first matching attribute as transformed by
    ///             `validate`. If this node is not an element node, or if there
    ///             are no matches, this method returns `nil`.
    ///
    /// - Throws:   `Error.invalidAttributeValue` if the attribute value is
    ///             invalid according to `validate`.
    public func valueOfOptionalAttribute<T>(_ attr: A,
                                            _ validate: (String) -> T? = { $0 }) throws(Error) -> T? {
        try valueOfOptionalAttribute([attr], validate)
    }

    /// Returns the transformed value of the first attribute of this node
    /// matching any of the provided ``XMLAttribute`` instances.
    ///
    /// - Parameter attrs:      An array of ``XMLAttribute`` instances to match.
    /// - Parameter validate:   A validation closure. `validate` accepts a
    ///                         string value as its parameter and optionally
    ///                         returns a transformed value of the same or of a
    ///                         different type. If `validate` returns `nil`, the
    ///                         string value is considered to be invalid. By
    ///                         default, returns the value untransformed.
    ///
    /// - Returns:  The value of the first matching attribute as transformed by
    ///             `validate`. If this node is not an element node, or if there
    ///             are no matches, this method returns `nil`.
    ///
    /// - Throws:   `Error.invalidAttributeValue` if the attribute value is
    ///             invalid according to `validate`.
    public func valueOfOptionalAttribute<T>(_ attrs: [A],
                                            _ validate: (String) -> T? = { $0 }) throws(Error) -> T? {
        guard let attributes,
              let attrValue = _firstAttribute(attrs, attributes)
        else { return nil }

        let (value, strValue, isValid) = _validateValue(attrValue, validate)

        guard isValid, let value
        else { throw Error.invalidAttributeValue(attrs.map { $0.name }, strValue) }

        return value
    }

    /// Returns the transformed ``value`` of the first child element node of
    /// this node matching the provided ``XMLElement`` instance.
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
    ///             transformed by `validate`. If this node is not an element
    ///             node, or if there are no matches, this method returns `nil`.
    ///
    /// - Throws:   `Error.invalidElementValue` if the element value is invalid
    ///             according to `validate`.
    public func valueOfOptionalChildElement<T>(_ elem: E,
                                               _ validate: (String) -> T? = { $0 }) throws(Error) -> T? {
        try valueOfOptionalChildElement([elem], validate)
    }

    /// Returns the transformed ``value`` of the first child element node of
    /// this node matching any of the provided ``XMLElement`` instances.
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
    ///             transformed by `validate`. If this node is not an element
    ///             node, or if there are no matches, this method returns `nil`.
    ///
    /// - Throws:   `Error.invalidElementValue` if the element value is invalid
    ///             according to `validate`.
    public func valueOfOptionalChildElement<T>(_ elems: [E],
                                               _ validate: (String) -> T? = { $0 }) throws(Error) -> T? {
        guard let node = firstChildElement(elems)
        else { return nil }

        let (value, strValue, isValid) = _validateValue(node.value, validate)

        guard isValid, let value
        else { throw Error.invalidElementValue(elems.map { $0.name }, strValue) }

        return value
    }

    /// Returns the transformed value of the first attribute of this node
    /// matching the provided ``XMLAttribute`` instance.
    ///
    /// - Parameter attr:       An ``XMLAttribute`` instance to match.
    /// - Parameter validate:   A validation closure. `validate` accepts a
    ///                         string value as its parameter and optionally
    ///                         returns a transformed value of the same or of a
    ///                         different type. If `validate` returns `nil`, the
    ///                         string value is considered to be invalid. By
    ///                         default, returns the value untransformed.
    ///
    /// - Returns:  The value of the first matching attribute as transformed by
    ///             `validate`.
    ///
    /// - Throws:   `Error.missingRequiredAttribute` if this node is not an
    ///             element node, or if there are no matches.
    ///             `Error.invalidAttributeValue` if the attribute value is
    ///             invalid according to `validate`.
    public func valueOfRequiredAttribute<T>(_ attr: A,
                                            _ validate: (String) -> T? = { $0 }) throws(Error) -> T {
        try valueOfRequiredAttribute([attr], validate)
    }

    /// Returns the transformed value of the first attribute of this node
    /// matching any of the provided ``XMLAttribute`` instances.
    ///
    /// - Parameter attrs:      An array of ``XMLAttribute`` instances to match.
    /// - Parameter validate:   A validation closure. `validate` accepts a
    ///                         string value as its parameter and optionally
    ///                         returns a transformed value of the same or of a
    ///                         different type. If `validate` returns `nil`, the
    ///                         string value is considered to be invalid. By
    ///                         default, returns the value untransformed.
    ///
    /// - Returns:  The value of the first matching attribute as transformed by
    ///             `validate`.
    ///
    /// - Throws:   `Error.missingRequiredAttribute` if this node is not an
    ///             element node, or if there are no matches.
    ///             `Error.invalidAttributeValue` if the attribute value is
    ///             invalid according to `validate`.
    public func valueOfRequiredAttribute<T>(_ attrs: [A],
                                            _ validate: (String) -> T? = { $0 }) throws(Error) -> T {
        guard let attributes,
              let attrValue = _firstAttribute(attrs, attributes)
        else { throw try Error.missingRequiredAttribute(_requireName(), attrs.map { $0.name }) }

        let (value, strValue, isValid) = _validateValue(attrValue, validate)

        guard isValid, let value
        else { throw Error.invalidAttributeValue(attrs.map { $0.name }, strValue) }

        return value
    }

    /// Returns the transformed ``value`` of the first child element node of
    /// this node matching the provided ``XMLElement`` instance.
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
    /// - Throws:   `Error.missingRequiredChildElement` if this node is not an
    ///             element node, or if there are no matches.
    ///             `Error.invalidElementValue` if the element value is invalid
    ///             according to `validate`.
    public func valueOfRequiredChildElement<T>(_ elem: E,
                                               _ validate: (String) -> T? = { $0 }) throws(Error) -> T {
        try valueOfRequiredChildElement([elem], validate)
    }

    /// Returns the transformed ``value`` of the first child element node of
    /// this node matching any of the provided ``XMLElement`` instances.
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
    /// - Throws:   `Error.missingRequiredChildElement` if this node is not an
    ///             element node, or if there are no matches.
    ///             `Error.invalidElementValue` if the element value is invalid
    ///             according to `validate`.
    public func valueOfRequiredChildElement<T>(_ elems: [E],
                                               _ validate: (String) -> T? = { $0 }) throws(Error) -> T {
        guard let node = firstChildElement(elems)
        else { throw try Error.missingRequiredChildElement(_requireName(), elems.map { $0.name }) }

        let (value, strValue, isValid) = _validateValue(node.value, validate)

        guard isValid, let value
        else { throw Error.invalidElementValue(elems.map { $0.name }, strValue) }

        return value
    }

    // MARK: Private Instance Methods

    private func _requireName() throws(Error) -> String {
        guard let name
        else { throw Error.internalFailure }

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
