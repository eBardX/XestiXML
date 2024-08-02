// © 2024 John Gary Pusey (see LICENSE.md)

public protocol XMLAttribute: Equatable, Hashable {
    init?(_ name: String)

    var name: String { get }
}

// MARK: - (defaults)

extension XMLAttribute where Self: RawRepresentable,
                             Self.RawValue == String {

    // MARK: Public Initializers

    public init?(_ name: String) {
        self.init(rawValue: name)
    }

    // MARK: Public Instance Properties

    public var name: String {
        rawValue
    }
}
