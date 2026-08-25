// © 2026 John Gary Pusey (see LICENSE.md)

public import Foundation

/// A simplified XML formatter.
///
/// `XMLFormatter` serializes a type-safe tree of ``XMLNode`` instances into an
/// XML document. It is the inverse of ``XMLParser`` and, as such, is equally
/// _simple_ in that only elements, with any associated attributes, text,
/// comments, and processing instructions are represented in the resulting XML
/// document. Other XML items (such as CDATA blocks and the declarations within
/// the internal subset of a document type declaration) cannot be generated.
///
/// Elements and attributes are mapped from custom ``XMLElement`` and
/// ``XMLAttribute`` types, respectively.
///
/// Each comment and processing instruction in the XML node tree is emitted
/// where it appears unless ``Options/stripsComments`` or
/// ``Options/stripsProcessingInstructions`` is enabled, in which case it is
/// omitted. These mirror the options of the same name on ``XMLParser``, so a
/// tree may be stripped as it is parsed, as it is formatted, or both.
///
/// ``format(_:)`` takes an ``XMLDocument``, so an entire XML document is
/// emitted — including its document type declaration and anything in its
/// prolog and epilog. Wrap a bare ``XMLNode`` in `XMLDocument(root:)` to format
/// an XML node tree with no such surroundings.
///
/// An ``XMLNode`` tree records namespace _URIs_, never prefixes, so the
/// prefixes are chosen here. Every namespace declaration is emitted on the root
/// element, and ``Options/namespaces`` says what those declarations are. A URI
/// left unmentioned is still written correctly: it becomes the default
/// namespace if every element in the tree carries it, and otherwise receives a
/// generated prefix. A document using a single namespace throughout therefore
/// needs no configuration, and is written exactly as it would be by hand.
///
/// Two consequences are worth stating plainly. An attribute in a namespace is
/// _always_ written with a prefix, even when its URI is also the default
/// namespace, because an unprefixed attribute name is in no namespace at all.
/// And a namespace declaration cannot be written as an ordinary attribute: any
/// attribute name beginning with `xmlns` is rejected as reserved.
///
/// Note that a document using more than one namespace does not survive a parse
/// and reformat byte for byte, since the prefixes it is written with are chosen
/// rather than recovered. What survives is meaning — every name resolves to the
/// namespace it resolved to before — and formatting is idempotent thereafter.
///
/// An emitted XML declaration is always a complete one, naming a version, an
/// encoding, and whether the document is standalone, whatever the
/// ``XMLDeclaration`` being formatted left out. Each omission has a value the
/// XML specification assumes on a reader’s behalf — UTF-8 for an unnamed
/// encoding, `no` for an absent `standalone` — so writing them out states what
/// the document already meant, and leaves nothing about how it is to be read
/// resting on a default the reader has to know. A declaration that named only a
/// version therefore does not come back byte for byte, though it comes back
/// saying the same thing, and formatting is idempotent thereafter.
///
/// The bytes produced are in the character encoding named by the XML
/// declaration that is emitted, since that declaration is all a reader has to go
/// by. A document is therefore written in UTF-8 unless its ``XMLDocument``
/// carries an ``XMLDeclaration`` naming some other encoding _and_
/// ``Options/emitsXMLDeclaration`` is enabled — bytes nobody can decode are of
/// no use to anyone, so suppressing the declaration also suppresses the choice
/// of encoding. The encoding must be one the system knows by the IANA charset
/// name the declaration spells it with, and it must be one an XML parser can be
/// expected to read back, which rules out the UTF-32 family.
///
/// An encoding narrower than Unicode need not be able to carry every character
/// in the document. In text and attribute values, one it cannot carry is written
/// as a numeric character reference — `caf&#xe9;` in US-ASCII — which a parser
/// reads back as the character itself, so the document survives an encoding that
/// has never heard of it. Everywhere else, it does not: a reference is markup,
/// and inside an element name, a comment, or a processing instruction it would
/// be read as the literal characters that spell it. A name or a comment the
/// encoding cannot carry is therefore an error rather than an approximation.
///
/// Attributes are always emitted in ascending order by name and namespace URI,
/// so formatting the same XML node tree twice always produces identical
/// results.
///
/// An `XMLFormatter` instance is immutable and may be used to format any number
/// of XML node trees concurrently.
public struct XMLFormatter<E: XMLElement, A: XMLAttribute> {

    // MARK: Public Initializers

    /// Creates a new `XMLFormatter` instance.
    ///
    /// - Parameter options:    The options that control how an XML document is
    ///                         formatted.
    public init(options: Options = Options()) {
        self.options = options
    }

    // MARK: Public Instance Properties

    /// The options that control how an XML document is formatted.
    public let options: Options
}

// MARK: -

extension XMLFormatter {

    // MARK: Public Instance Methods

    /// Formats the provided XML document.
    ///
    /// The document type declaration and any comments and processing
    /// instructions in the prolog and epilog are emitted along with the root
    /// element and its descendants. To format an XML node tree that has no such
    /// surroundings, wrap it: `XMLDocument(root: node)`.
    ///
    /// If ``Options/emitsXMLDeclaration`` is enabled, the XML declaration of
    /// the provided XML document is emitted, completed as described by
    /// ``XMLFormatter``; if it has none, a declaration of
    /// `<?xml version="1.0" encoding="UTF-8" standalone="no"?>` is emitted
    /// instead.
    ///
    /// The returned bytes are in the character encoding that the emitted XML
    /// declaration names, so a document declaring `encoding="ISO-8859-1"` is
    /// written in ISO 8859-1. A character the encoding cannot carry is written
    /// as a numeric character reference where XML allows one, and is an error
    /// where it does not; it is never approximated or dropped.
    ///
    /// - Parameter document:   The ``XMLDocument`` representing the XML
    ///                         document to format.
    ///
    /// - Returns:  A `Data` instance containing the encoded XML document.
    ///
    /// - Throws:   ``Error`` if the XML document cannot be formatted.
    public func format(_ document: XMLDocument<E, A>) throws(Error) -> Data {
        var writer = Writer(options)

        try writer.writeDocument(document)

        return try writer.encodedText()
    }
}

// MARK: - Sendable

extension XMLFormatter: Sendable {
}
