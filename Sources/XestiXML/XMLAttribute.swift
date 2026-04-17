// © 2024–2026 John Gary Pusey (see LICENSE.md)

public import XestiTools

/// A type-safe XML attribute.
public protocol XMLAttribute: Equatable, Hashable, Sendable {
    /// Creates a new XML attribute with the provided name.
    ///
    /// - Parameter name:   The name of the XML attribute.
    ///
    /// - Precondition: The provided name must not be empty.
    init(_ name: String)

    /// Creates a new XML attribute with the provided name.
    ///
    /// If the provided name is empty, this initializer returns `nil`.
    ///
    /// - Parameter name:   The name of the XML attribute.
    init?(name: String)

    /// The name of the XML attribute.
    var name: String { get }
}

// MARK: - (defaults) - (RawRepresentable)

extension XMLAttribute where Self: RawRepresentable,
                             Self.RawValue == String {

    // MARK: Public Initializers

    public init(_ name: String) {
        self.init(rawValue: name)!  // swiftlint:disable:this force_unwrapping
    }

    public init?(name: String) {
        self.init(rawValue: name)
    }

    // MARK: Public Instance Properties

    public var name: String {
        rawValue
    }
}

// MARK: - (defaults) - (StringRepresentable)

extension XMLAttribute where Self: StringRepresentable {

    // MARK: Public Initializers

    public init(_ name: String) {
        self.init(stringValue: name)!   // swiftlint:disable:this force_unwrapping
    }

    public init?(name: String) {
        self.init(stringValue: name)
    }

    // MARK: Public Instance Properties

    public var name: String {
        stringValue
    }
}
