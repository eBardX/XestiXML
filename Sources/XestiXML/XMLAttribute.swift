// © 2024 John Gary Pusey (see LICENSE.md)

import XestiTools

public protocol XMLAttribute: Equatable, Hashable {
    init?(name: String)

    init(_ name: String)

    var name: String { get }
}

// MARK: - (defaults) - (RawRepresentable)

extension XMLAttribute where Self: RawRepresentable,
                             Self.RawValue == String {

    // MARK: Public Initializers

    public init?(name: String) {
        self.init(rawValue: name)
    }

    public init(_ name: String) {
        self.init(rawValue: name)!  // swiftlint:disable:this force_unwrapping
    }

    // MARK: Public Instance Properties

    public var name: String {
        rawValue
    }
}

// MARK: - (defaults) - (StringRepresentable)

extension XMLAttribute where Self: StringRepresentable {

    // MARK: Public Initializers

    public init?(name: String) {
        self.init(stringValue: name)
    }

    public init(_ name: String) {
        self.init(name)
    }

    // MARK: Public Instance Properties

    public var name: String {
        stringValue
    }
}
