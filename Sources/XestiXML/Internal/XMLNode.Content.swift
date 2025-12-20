// © 2025 John Gary Pusey (see LICENSE.md)

extension XMLNode {
    internal enum Content {
        case attr(A, String)
        case elem(E, [XMLNode])
        case text(String)
    }
}

// MARK: - Sendable

extension XMLNode.Content: Sendable {
}
