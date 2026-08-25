// © 2022–2026 John Gary Pusey (see LICENSE.md)

public import Foundation

private import XestiTools

/// A simplified XML parser.
///
/// `XMLParser` drives the SAX2 interface of `libxml2` and hides all the
/// machinery needed to build a type-safe tree of ``XMLNode`` instances
/// representing the parsed XML document source. Essentially, `XMLParser`
/// converts an XML document into a very simple “DOM”. It is _simple_ in that
/// only elements, with any associated attributes, text, comments, and
/// processing instructions are represented in the resulting tree. CDATA blocks
/// are converted to text.
///
/// Whitespace in character data is normalized — leading and trailing whitespace
/// is stripped, runs of whitespace are collapsed to a single space, and a run of
/// nothing but whitespace is discarded entirely — _unless_ the enclosing element
/// is under `xml:space="preserve"`, in which case the text is taken exactly as
/// written. Preservation is inherited by descendants until a descendant asks for
/// `xml:space="default"`, and it means that a run of nothing but whitespace
/// becomes a text node of its own rather than vanishing. An `xml:space` value
/// other than these two is not valid XML; it is ignored rather than rejected,
/// exactly as if the attribute were absent.
///
/// Note that the typed accessors in ``XMLNode`` normalize whitespace when
/// extracting a value, whether or not it was preserved. Preserved text is
/// visible through ``XMLNode/value`` and through the text nodes themselves.
///
/// Elements and attributes are mapped to custom ``XMLElement`` and
/// ``XMLAttribute`` types, respectively.
///
/// Each comment and processing instruction becomes an ``XMLNode`` of its own
/// unless ``Options/stripsComments`` or
/// ``Options/stripsProcessingInstructions`` is enabled, in which case it is
/// ignored. Neither is character data, so neither contributes to the value of
/// the element containing it.
///
/// Parsing yields an ``XMLDocument``, which carries everything that surrounds
/// the root element — the XML declaration, the document type declaration, and
/// any comments and processing instructions in the prolog and epilog:
///
/// ```swift
/// let document = try XMLParser<E, A>().parse(data)
///
/// document.root       // the XML node tree alone
/// ```
///
/// The declarations _within_ the internal subset of a document type declaration
/// are always ignored, as are any comments and processing instructions
/// appearing among them.
///
/// External content is _never_ fetched. External DTD subsets and external
/// entities are not loaded from the network or from the file system, so a
/// reference to an entity declared `SYSTEM` or `PUBLIC` is reported as an
/// undefined-entity parse error rather than resolved. Entity expansion limits
/// are left at their defaults, so exponential-expansion (“billion laughs”)
/// documents fail with an error instead of exhausting memory.
///
/// Elements and attributes alike are reported as a local name accompanied by a
/// namespace URI; the prefix a name was written with is discarded, since it is
/// a lexical accident of the source rather than part of the name’s identity.
/// Two attributes therefore remain distinct when they share a local name but
/// differ in namespace, and a namespace declaration is never reported as an
/// attribute. Note that an unprefixed attribute name is in _no_ namespace, and
/// so is reported with a `nil` URI even when the enclosing element declares a
/// default namespace — which is what the Namespaces in XML specification
/// requires.
///
/// Attributes given a default value by an `<!ATTLIST>` declaration in the
/// internal subset are reported exactly as if they had appeared explicitly in
/// the document. This is deliberate: XML requires such an attribute to be
/// supplied, so it is genuinely part of the document, and discarding it would
/// silently yield `nil` for a value the document actually carries. The
/// consequence is that an ``XMLAttribute`` type must recognize every defaulted
/// attribute name as well as every written one; otherwise parsing fails with
/// ``Error/unrecognizedAttribute(_:_:_:)`` naming an attribute that appears
/// nowhere in the document source. Adding that name to the ``XMLAttribute``
/// type resolves it.
///
/// Note that `XMLParser` has a few remaining limitations. These have been
/// verified empirically on macOS; the behavior may differ on other platforms.
///
/// - References to entities declared in an internal DTD subset are expanded in
///   element content but _not_ in attribute values. Given a declaration of
///   `<!ENTITY e "value">`, the text of `<root>&e;</root>` is `value`, but the
///   attribute value of `<root name="&e;"/>` is the literal string `&e;`.
///   Predefined entities (such as `&amp;`) and numeric character references
///   (such as `&#65;`) are resolved normally in both positions.
///
/// - XML 1.1 is not supported. A document declaring any version other than
///   `1.0` is parsed as if it had declared `1.0`, so neither the additional
///   name characters nor the extra line-ending normalization of XML 1.1 is
///   honored. A declared version outside the `1.x` range fails with
///   ``Error/parseFailure(_:_:_:)``.
public struct XMLParser<E: XMLElement, A: XMLAttribute> {

    // MARK: Public Initializers

    /// Creates a new `XMLParser` instance.
    ///
    /// - Parameter options:    The options that control how an XML document is
    ///                         parsed.
    public init(options: Options = Options()) {
        self.options = options
    }

    // MARK: Public Instance Properties

    /// The options that control how an XML document is parsed.
    public let options: Options
}

// MARK: -

extension XMLParser {

    // MARK: Public Instance Methods

    /// Parses the provided XML document.
    ///
    /// The entire document is represented — the XML declaration, the document
    /// type declaration, and any comments and processing instructions appearing
    /// before or after the root element, as well as the root element itself.
    /// Use ``XMLDocument/root`` to reach the root element alone.
    ///
    /// Note that comments and processing instructions are represented unless
    /// ``Options/stripsComments`` and
    /// ``Options/stripsProcessingInstructions`` are enabled, respectively.
    ///
    /// - Parameter data:   A `Data` instance containing the XML document to
    ///                     parse.
    ///
    /// - Returns:  The ``XMLDocument`` representing the parsed XML document.
    ///
    /// - Throws:   ``Error`` if the XML document cannot be parsed.
    public func parse(_ data: Data) throws(Error) -> XMLDocument<E, A> {
        let context = try _parse(data)

        return try XMLDocument(declaration: context.declaration,
                               documentType: context.documentType,
                               prolog: context.prolog,
                               root: context.result.get(),
                               epilog: context.epilog)
    }

    // MARK: Private Instance Methods

    private func _parse(_ data: Data) throws(Error) -> Context {
        let sink = EventSink(options)

        guard saxParse(data, sink)
        else { throw (sink.context.result.failure ?? Error.internalFailure) }

        return sink.context
    }
}
