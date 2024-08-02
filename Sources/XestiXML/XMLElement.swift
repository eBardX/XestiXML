// © 2024 John Gary Pusey (see LICENSE.md)

public protocol XMLElement: Equatable {
    init?(_ name: String,
          _ uri: String)

    var name: String { get }
    var uri: String { get }
}

// MARK: - (defaults)

extension XMLElement where Self: RawRepresentable,
                           Self.RawValue == String {

    // MARK: Public Initializers

    public init?(_ name: String,
                 _ uri: String) {
        guard uri.isEmpty
        else { return nil }

        self.init(rawValue: name)
    }

    // MARK: Public Instance Properties

    public var name: String {
        rawValue
    }

    public var uri: String {
        ""
    }
}
