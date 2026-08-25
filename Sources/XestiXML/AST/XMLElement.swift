// © 2024–2026 John Gary Pusey (see LICENSE.md)

public import XestiTools

/// A type-safe XML element.
///
/// Default implementations of every requirement are provided for a conforming
/// type that is also `RawRepresentable` with a `String` raw value, or that
/// conforms to `StringRepresentable`. Such a type represents a name alone, so
/// those defaults are more restrictive than the requirements themselves:
/// ``uri`` is always `nil`; ``init(name:uri:)`` returns `nil` unless the
/// provided URI is `nil` and the provided name is one the conforming type
/// recognizes; and ``init(_:_:)`` traps in either of those cases rather than
/// returning `nil`.
public protocol XMLElement: Equatable, Sendable {
    /// Creates a new XML element with the provided name and namespace URI.
    ///
    /// - Parameter name:   The name of the XML element.
    /// - Parameter uri:    The optional namespace URI of the XML element.
    ///
    /// - Precondition: The provided name must not be empty.
    init(_ name: String,
         _ uri: String?)

    /// Creates a new XML element with the provided name and namespace URI.
    ///
    /// If the provided name is empty, this initializer returns `nil`.
    ///
    /// - Parameter name:   The name of the XML element.
    /// - Parameter uri:    The optional namespace URI of the XML element.
    init?(name: String,
          uri: String?)

    /// The name of the XML element.
    var name: String { get }

    /// The optional namespace URI of the XML element.
    var uri: String? { get }
}

// MARK: - (defaults) - (RawRepresentable)

extension XMLElement where Self: RawRepresentable,
                           Self.RawValue == String {

    // MARK: Public Initializers

    public init(_ name: String,
                _ uri: String?) {
        guard uri == nil
        else { fatalError("uri must be nil!") }

        self.init(rawValue: name)!  // swiftlint:disable:this force_unwrapping
    }

    public init?(name: String,
                 uri: String?) {
        guard uri == nil
        else { return nil }

        self.init(rawValue: name)
    }

    // MARK: Public Instance Properties

    public var name: String {
        rawValue
    }

    public var uri: String? {
        nil
    }
}

// MARK: - (defaults) - (StringRepresentable)

extension XMLElement where Self: StringRepresentable {

    // MARK: Public Initializers

    public init(_ name: String,
                _ uri: String?) {
        guard uri == nil
        else { fatalError("uri must be nil!") }

        self.init(stringValue: name)!   // swiftlint:disable:this force_unwrapping
    }

    public init?(name: String,
                 uri: String?) {
        guard uri == nil
        else { return nil }

        self.init(stringValue: name)
    }

    // MARK: Public Instance Properties

    public var name: String {
        stringValue
    }

    public var uri: String? {
        nil
    }
}
