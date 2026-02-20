// © 2024–2026 John Gary Pusey (see LICENSE.md)

import XestiTools

public protocol XMLElement: Equatable, Sendable {
    init(_ name: String,
         _ uri: String?)

    init?(name: String,
          uri: String?)

    var name: String { get }
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

        self.init(name)
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
