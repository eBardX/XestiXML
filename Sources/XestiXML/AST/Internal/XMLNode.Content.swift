// © 2025–2026 John Gary Pusey (see LICENSE.md)

extension XMLNode {
    internal enum Content {
        case comment(String)
        case element(E, [A: String], [XMLNode])
        case processingInstruction(String, String?)
        case text(String)
    }
}

// MARK: - Sendable

extension XMLNode.Content: Sendable {
}
