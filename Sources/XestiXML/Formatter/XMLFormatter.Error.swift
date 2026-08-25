// © 2026 John Gary Pusey (see LICENSE.md)

public import XestiTools

extension XMLFormatter {

    // MARK: Public Nested Types

    /// An error that occurs while formatting the XML node tree.
    ///
    /// Additional cases may be added in a future release, so prefer a `default`
    /// case when switching over an `Error` value; an exhaustive switch will stop
    /// compiling when one is.
    public enum Error {
        /// An attribute name that is not a valid XML name was encountered while
        /// formatting the XML node tree.
        ///
        /// As an associated value, this case contains the invalid attribute
        /// name.
        case invalidAttributeName(String)

        /// An attribute value containing a character that cannot be represented
        /// in an XML document was encountered while formatting the XML node
        /// tree.
        ///
        /// As associated values, this case contains the attribute name, as well
        /// as the invalid attribute value.
        case invalidAttributeValue(String, String)

        /// A comment node that cannot be represented in an XML document was
        /// encountered while formatting the XML node tree.
        ///
        /// The text of a comment must not contain a double hyphen and must not
        /// end with a hyphen, and there is no way to escape either.
        ///
        /// As an associated value, this case contains the invalid comment text.
        case invalidCommentValue(String)

        /// A document type declaration that cannot be represented in an XML
        /// document was encountered while formatting the XML node tree.
        ///
        /// As an associated value, this case contains the name of the root
        /// element of the invalid document type declaration.
        case invalidDocumentType(String)

        /// An element name that is not a valid XML name was encountered while
        /// formatting the XML node tree.
        ///
        /// As an associated value, this case contains the invalid element name.
        case invalidElementName(String)

        /// A namespace binding that cannot be written as a declaration was
        /// encountered in ``Options/namespaces``.
        ///
        /// A prefix must be a valid XML name containing no colon, and must be
        /// neither `xmlns` nor `xml` (which is permanently bound to the XML
        /// namespace). A URI must not be empty. No prefix and no URI may be
        /// bound twice.
        ///
        /// As associated values, this case contains the prefix — `nil` for a
        /// default namespace — as well as the URI.
        case invalidNamespace(String?, String)

        /// A processing instruction node whose data cannot be represented in an
        /// XML document was encountered while formatting the XML node tree.
        ///
        /// The data of a processing instruction must not contain `?>`, and there
        /// is no way to escape it.
        ///
        /// As associated values, this case contains the target of the processing
        /// instruction, as well as the invalid data.
        case invalidProcessingInstructionData(String, String)

        /// A processing instruction node whose target is not a valid XML name,
        /// or is the reserved name `xml`, was encountered while formatting the
        /// XML node tree.
        ///
        /// As an associated value, this case contains the invalid target.
        case invalidProcessingInstructionTarget(String)

        /// A text node containing a character that cannot be represented in an
        /// XML document was encountered while formatting the XML node tree.
        ///
        /// As an associated value, this case contains the invalid text value.
        case invalidTextValue(String)

        /// An XML declaration specifying a version that is not a valid XML
        /// version number was encountered while formatting the XML node tree.
        ///
        /// As an associated value, this case contains the invalid version.
        case invalidXMLVersion(String)

        /// An attribute name reserved for namespace declarations was encountered
        /// while formatting the XML node tree.
        ///
        /// As an associated value, this case contains the reserved attribute
        /// name.
        case reservedAttributeName(String)

        /// A node other than a comment or a processing instruction was
        /// encountered in the prolog or the epilog of the XML document.
        ///
        /// An XML document permits only comments and processing instructions
        /// outside its root element.
        case unexpectedNodeOutsideRootElement

        /// A node other than an element node was encountered as the root of the
        /// XML node tree.
        ///
        /// An XML document requires a single element as its root.
        case unexpectedRootTextNode

        /// Markup that the character encoding named by the XML declaration
        /// cannot represent was encountered while formatting the XML node tree.
        ///
        /// Text and attribute values are not subject to this: a character an
        /// encoding cannot carry is written there as a numeric character
        /// reference. A reference is itself markup, though, and means nothing
        /// inside a name, a comment, or a processing instruction — so a
        /// character that cannot be encoded in one of those places cannot be
        /// written at all, and the document is not silently altered to make it
        /// fit.
        ///
        /// As associated values, this case contains the offending markup, as
        /// well as the name of the encoding, exactly as the XML declaration
        /// spells it.
        case unrepresentableContent(String, String)

        /// An XML declaration naming a character encoding that cannot be written
        /// was encountered while formatting the XML node tree.
        ///
        /// The name must be one of the IANA charset names — `UTF-8`,
        /// `ISO-8859-1`, `windows-1252`, and so forth — under which the encoding
        /// is registered, or one of its registered aliases.
        ///
        /// A name the system does not recognize at all is one reason for this
        /// error. The other is the UTF-32 family, which is refused deliberately:
        /// the XML specification requires a parser to support only UTF-8 and
        /// UTF-16, and a UTF-32 document is in practice mistaken for a UTF-16
        /// one by the parsers that meet it.
        ///
        /// As an associated value, this case contains the unrecognized encoding
        /// name.
        case unsupportedEncoding(String)
    }
}

// MARK: - EnhancedError

extension XMLFormatter.Error: EnhancedError {

    // MARK: Public Instance Properties

    public var message: String {
        switch self {
        case let .invalidAttributeName(name):
            "Invalid attribute name: \(name)"

        case let .invalidAttributeValue(name, value):
            "Invalid value for \(name) attribute: “\(value)”"

        case let .invalidCommentValue(value):
            "Invalid comment value: “\(value)”"

        case let .invalidDocumentType(name):
            "Invalid document type declaration: \(name)"

        case let .invalidElementName(name):
            "Invalid element name: \(name)"

        case let .invalidNamespace(prefix, uri):
            if let prefix {
                "Invalid namespace declaration: xmlns:\(prefix)=“\(uri)”"
            } else {
                "Invalid namespace declaration: xmlns=“\(uri)”"
            }

        case let .invalidProcessingInstructionData(target, data):
            "Invalid data for \(target) processing instruction: “\(data)”"

        case let .invalidProcessingInstructionTarget(target):
            "Invalid processing instruction target: \(target)"

        case let .invalidTextValue(value):
            "Invalid text value: “\(value)”"

        case let .invalidXMLVersion(version):
            "Invalid XML version: \(version)"

        case let .reservedAttributeName(name):
            "Reserved attribute name: \(name)"

        case .unexpectedNodeOutsideRootElement:
            "Unexpected node outside root element of XML node tree"

        case .unexpectedRootTextNode:
            "Unexpected text node as root of XML node tree"

        case let .unrepresentableContent(markup, encoding):
            "Cannot encode “\(markup)” in \(encoding)"

        case let .unsupportedEncoding(encoding):
            "Unsupported character encoding: \(encoding)"
        }
    }
}

// MARK: - Sendable

extension XMLFormatter.Error: Sendable {
}
