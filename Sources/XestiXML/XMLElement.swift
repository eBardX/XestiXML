// © 2024 John Gary Pusey (see LICENSE.md)

import XestiTools

public protocol XMLElement: Equatable {
    init?(name: String,
          uri: String)

    init(_ name: String,
         _ uri: String)

    var name: String { get }
    var uri: String { get }
}

// MARK: - (defaults) - (RawRepresentable)

extension XMLElement where Self: RawRepresentable,
                           Self.RawValue == String {

    // MARK: Public Initializers

    public init?(name: String,
                 uri: String) {
        guard uri.isEmpty
        else { return nil }

        self.init(rawValue: name)
    }

    public init(_ name: String,
                _ uri: String) {
        guard uri.isEmpty
        else { fatalError("uri must be empty!") }

        self.init(rawValue: name)!  // swiftlint:disable:this force_unwrapping
    }

    // MARK: Public Instance Properties

    public var name: String {
        rawValue
    }

    public var uri: String {
        ""
    }
}

// MARK: - (defaults) - (StringRepresentable)

extension XMLElement where Self: StringRepresentable {

    // MARK: Public Initializers

    public init?(name: String,
                 uri: String) {
        guard uri.isEmpty
        else { return nil }

        self.init(stringValue: name)
    }

    public init(_ name: String,
                _ uri: String) {
        guard uri.isEmpty
        else { fatalError("uri must be empty!") }

        self.init(name)
    }

    // MARK: Public Instance Properties

    public var name: String {
        stringValue
    }

    public var uri: String {
        ""
    }
}
