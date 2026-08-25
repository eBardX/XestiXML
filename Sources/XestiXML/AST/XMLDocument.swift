// © 2026 John Gary Pusey (see LICENSE.md)

/// An entire XML document: a root element, together with everything that
/// surrounds it.
///
/// ``XMLNode`` represents a _node_ in the XML node tree, and the tree is rooted
/// at the root element. An XML document, however, is more than that tree — an
/// XML declaration, a document type declaration, and any number of comments and
/// processing instructions may appear outside the root element, where there is
/// no node to hang them from. `XMLDocument` is that surrounding context:
///
/// ```swift
/// let document = try XMLParser<E, A>().parse(data)
///
/// document.documentType?.publicID    // "-//Recordare//DTD MusicXML 4.0 Partwise//EN"
/// document.root.element              // .scorePartwise
/// ```
///
/// A document need not come from parsing. One constructed directly — a root
/// element, plus whatever surrounding context is wanted — is exactly what
/// ``XMLFormatter`` writes:
///
/// ```swift
/// let document = XMLDocument(declaration: XMLDeclaration(),
///                            root: XMLNode(element: .scorePartwise))
/// ```
///
/// The `prolog` and `epilog` may contain only comment and processing
/// instruction nodes, since those are the only things XML permits outside the
/// root element.
public struct XMLDocument<E: XMLElement, A: XMLAttribute> {

    // MARK: Public Initializers

    /// Creates a new XML document.
    ///
    /// - Parameter declaration:    The XML declaration, or `nil` (the default)
    ///                             if there is none.
    /// - Parameter documentType:   The document type declaration, or `nil` (the
    ///                             default) if there is none.
    /// - Parameter prolog:         The comment and processing instruction nodes
    ///                             preceding the root element. The default is
    ///                             an empty array.
    /// - Parameter root:           The ``XMLNode`` representing the root
    ///                             element.
    /// - Parameter epilog:         The comment and processing instruction nodes
    ///                             following the root element. The default is
    ///                             an empty array.
    public init(declaration: XMLDeclaration? = nil,
                documentType: XMLDocumentType? = nil,
                prolog: [XMLNode<E, A>] = [],
                root: XMLNode<E, A>,
                epilog: [XMLNode<E, A>] = []) {
        self.declaration = declaration
        self.documentType = documentType
        self.epilog = epilog
        self.prolog = prolog
        self.root = root
    }

    // MARK: Public Instance Properties

    /// The XML declaration, or `nil` if there is none.
    public let declaration: XMLDeclaration?

    /// The document type declaration, or `nil` if there is none.
    public let documentType: XMLDocumentType?

    /// The comment and processing instruction nodes following the root element.
    public let epilog: [XMLNode<E, A>]

    /// The comment and processing instruction nodes preceding the root element.
    public let prolog: [XMLNode<E, A>]

    /// The ``XMLNode`` representing the root element.
    public let root: XMLNode<E, A>
}

// MARK: - Sendable

extension XMLDocument: Sendable {
}
