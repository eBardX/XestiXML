// © 2026 John Gary Pusey (see LICENSE.md)

internal import Foundation

private import XestiTools

extension XMLFormatter {

    // MARK: Internal Nested Types

    internal struct Writer {

        // MARK: Internal Initializers

        internal init(_ options: Options) {
            self.encoding = .utf8
            self.encodingName = "UTF-8"
            self.indentUnit = options.indentation.map {
                String(repeating: " ",
                       count: max($0, 0))
            }
            self.options = options
            self.repertoire = CharacterRepertoire(.utf8)
            self.table = NamespaceTable()
            self.text = ""
        }

        // MARK: Internal Instance Properties

        //
        // The encoding the written text is to be converted to, which is the one
        // the emitted XML declaration names — and UTF-8 whenever no declaration
        // is emitted, or the one emitted names no encoding.
        //
        internal private(set) var encoding: String.Encoding
        internal private(set) var encodingName: String
        internal private(set) var text: String

        // MARK: Private Instance Properties

        private let indentUnit: String?
        private let options: Options
        private var repertoire: CharacterRepertoire
        private var table: NamespaceTable
    }
}

// MARK: -

extension XMLFormatter.Writer {

    // MARK: Internal Instance Methods

    //
    // The written text, in the encoding the XML declaration named.
    //
    internal func encodedText() throws(XMLFormatter.Error) -> Data {
        guard let data = text.data(using: encoding)
        else {
            //
            // Every position that cannot carry a character reference is checked
            // as it is written, and every position that can is escaped, so this
            // is not reachable by any document. It stands against an encoding
            // with some quirk that neither of those accounts for, so that the
            // quirk is reported rather than silently producing nothing.
            //
            let culprit = repertoire.firstUnrepresentable(in: text).map { String($0) } ?? text

            throw XMLFormatter.Error.unrepresentableContent(culprit, encodingName)
        }

        return data
    }

    internal mutating func writeDocument(_ document: XMLDocument<E, A>) throws(XMLFormatter.Error) {
        guard case let .element(elem, attrs, kids) = document.root.content
        else { throw XMLFormatter.Error.unexpectedRootTextNode }

        //
        // Every namespace is resolved to a prefix before a byte is written, and
        // every declaration is emitted on the root element, so the writer itself
        // carries no namespace scope.
        //
        table = try XMLFormatter.NamespaceTable(options,
                                                document.root)

        if options.emitsXMLDeclaration {
            try _writeDeclaration(document.declaration ?? XMLDeclaration())

            _writeLineBreak(0)
        }

        if let documentType = document.documentType {
            try _writeDocumentType(documentType)

            _writeLineBreak(0)
        }

        for node in _retained(document.prolog) {
            try _writeNodeOutsideRootElement(node)

            _writeLineBreak(0)
        }

        try _writeElement(elem,
                          attrs,
                          kids,
                          0,
                          false,
                          true)

        for node in _retained(document.epilog) {
            _writeLineBreak(0)

            try _writeNodeOutsideRootElement(node)
        }

        _writeLineBreak(0)
    }

    // MARK: Private Instance Methods

    //
    // Guards a position in which a character reference cannot be written, and
    // in which a character the encoding cannot carry is therefore the end of the
    // matter. Names, comments, processing instructions, and the parts of a
    // document type declaration are all such positions.
    //
    private func _checkRepresentable(_ value: String) throws(XMLFormatter.Error) {
        guard repertoire.firstUnrepresentable(in: value) == nil
        else { throw XMLFormatter.Error.unrepresentableContent(value, encodingName) }
    }

    //
    // Whether an element asks for its whitespace to be left alone. An
    // unrecognized value is treated as absent, exactly as the parser treats it.
    //
    private func _preservesSpace(_ attributes: [A: String]) -> Bool {
        attributes.contains {
            $0.key.name == "space"
                && $0.key.uri == xmlNamespaceURI
                && $0.value == "preserve"
        }
    }

    //
    // Stripped nodes are removed before anything is written, so that neither
    // the line breaks between children nor the choice of an empty element tag
    // reflects a node that never appears in the output.
    //
    private func _retained(_ nodes: [XMLNode<E, A>]) -> [XMLNode<E, A>] {
        guard options.stripsComments
              || options.stripsProcessingInstructions
        else { return nodes }

        return nodes.filter {
            !(options.stripsComments && $0.isComment)
                && !(options.stripsProcessingInstructions && $0.isProcessingInstruction)
        }
    }

    private mutating func _writeAttribute(_ name: String,
                                          _ value: String) throws(XMLFormatter.Error) {
        try _checkRepresentable(name)

        guard let escValue = value.escapedXMLAttributeValue(repertoire)
        else { throw XMLFormatter.Error.invalidAttributeValue(name, value) }

        text += " \(name)=\"\(escValue)\""
    }

    private mutating func _writeComment(_ value: String) throws(XMLFormatter.Error) {
        guard value.isXMLCommentValue
        else { throw XMLFormatter.Error.invalidCommentValue(value) }

        try _checkRepresentable(value)

        text += "<!--\(value)-->"
    }

    private mutating func _writeDeclaration(_ declaration: XMLDeclaration) throws(XMLFormatter.Error) {
        guard declaration.version.isXMLVersion
        else { throw XMLFormatter.Error.invalidXMLVersion(declaration.version) }

        text += "<?xml version=\"\(declaration.version)\""

        //
        // Every pseudo-attribute is written, whether or not the declaration
        // being formatted named it, so that nothing about how the document is to
        // be read is left to a default the reader has to know.
        //
        // The declaration is the only thing that tells a reader how to decode
        // the bytes, so the encoding it names is the encoding they are written
        // in. One that cannot be resolved cannot be written in, either.
        //
        let name = declaration.encoding ?? "UTF-8"

        guard let enc = String.Encoding(xmlName: name)
        else { throw XMLFormatter.Error.unsupportedEncoding(name) }

        encoding = enc
        encodingName = name
        repertoire = CharacterRepertoire(encoding)

        text += " encoding=\"\(name)\""

        //
        // An absent standalone pseudo-attribute means `no`, which the XML
        // specification assumes on a reader's behalf; writing it says the same
        // thing without the reader having to know that.
        //
        text += " standalone=\"\((declaration.isStandalone ?? false) ? "yes" : "no")\""

        text += "?>"
    }

    private mutating func _writeDocumentType(_ documentType: XMLDocumentType) throws(XMLFormatter.Error) {
        let name = documentType.name

        guard name.isXMLName
        else { throw XMLFormatter.Error.invalidDocumentType(name) }

        try _checkRepresentable(name)

        text += "<!DOCTYPE \(name)"

        //
        // A public identifier is meaningful only alongside a system identifier,
        // so one without the other cannot be written at all.
        //
        switch (documentType.publicID, documentType.systemID) {
        case let (publicID?, systemID?):
            guard publicID.isXMLPublicID
            else { throw XMLFormatter.Error.invalidDocumentType(name) }

            //
            // A public identifier is drawn from an entirely ASCII repertoire, so
            // it needs no check of its own.
            //
            text += " PUBLIC \"\(publicID)\" "

            try _writeSystemID(systemID, name)

        case let (nil, systemID?):
            text += " SYSTEM "

            try _writeSystemID(systemID, name)

        case (nil, nil):
            break

        default:
            throw XMLFormatter.Error.invalidDocumentType(name)
        }

        text += ">"
    }

    private mutating func _writeElement(_ element: E,
                                        _ attributes: [A: String],
                                        _ allChildren: [XMLNode<E, A>],
                                        _ depth: Int,
                                        _ inline: Bool,
                                        _ isRoot: Bool) throws(XMLFormatter.Error) {
        let localName = element.name

        guard localName.isXMLNCName
        else { throw XMLFormatter.Error.invalidElementName(localName) }

        let name = table.elementName(localName,
                                     element.uri?.nilIfEmpty)

        try _checkRepresentable(name)

        text += "<\(name)"

        if isRoot {
            for (prefix, uri) in table.declarations {
                try _writeAttribute(prefix.map { "xmlns:\($0)" } ?? "xmlns",
                                    uri)
            }
        }

        //
        // Sorting on the namespace URI as well as the local name keeps the
        // order of two same-named attributes from different namespaces stable.
        //
        let sorted = attributes.sorted {
            ($0.key.name, $0.key.uri ?? "") < ($1.key.name, $1.key.uri ?? "")
        }

        for (attr, value) in sorted {
            let attrLocalName = attr.name

            //
            // The reservation is checked first: a declaration written as an
            // ordinary attribute is a mistake worth naming precisely, and
            // `xmlns:foo` would otherwise fail merely for containing a colon.
            //
            guard !attrLocalName.hasPrefix("xmlns")
            else { throw XMLFormatter.Error.reservedAttributeName(attrLocalName) }

            guard attrLocalName.isXMLNCName
            else { throw XMLFormatter.Error.invalidAttributeName(attrLocalName) }

            try _writeAttribute(table.attributeName(attrLocalName,
                                                    attr.uri?.nilIfEmpty),
                                value)
        }

        let children = _retained(allChildren)

        if children.isEmpty {
            text += "/>"
        } else {
            text += ">"

            //
            // Indenting the children of an element with mixed content would
            // alter the value of that element, so it must be avoided. So would
            // indenting inside `xml:space="preserve"`, whether or not any text
            // node is there to make the mixed-content test fire.
            //
            // Note that an inherited suppression is never lifted, not even by a
            // descendant asking for `xml:space="default"`. Erring towards less
            // indentation can only make the output plainer; erring the other way
            // would change what a document says.
            //
            let inlineKids = inline
                             || _preservesSpace(attributes)
                             || children.contains { $0.isText }

            for child in children {
                if !inlineKids {
                    _writeLineBreak(depth + 1)
                }

                try _writeNode(child,
                               depth + 1,
                               inlineKids)
            }

            if !inlineKids {
                _writeLineBreak(depth)
            }

            text += "</\(name)>"
        }
    }

    private mutating func _writeLineBreak(_ depth: Int) {
        guard let indentUnit
        else { return }

        text += "\n"

        for _ in 0..<depth {
            text += indentUnit
        }
    }

    private mutating func _writeNode(_ node: XMLNode<E, A>,
                                     _ depth: Int,
                                     _ inline: Bool) throws(XMLFormatter.Error) {
        switch node.content {
        case let .comment(value):
            try _writeComment(value)

        case let .element(elem, attrs, kids):
            try _writeElement(elem,
                              attrs,
                              kids,
                              depth,
                              inline,
                              false)

        case let .processingInstruction(target, data):
            try _writeProcessingInstruction(target,
                                            data)

        case let .text(value):
            try _writeText(value)
        }
    }

    private mutating func _writeNodeOutsideRootElement(_ node: XMLNode<E, A>) throws(XMLFormatter.Error) {
        switch node.content {
        case let .comment(value):
            try _writeComment(value)

        case let .processingInstruction(target, data):
            try _writeProcessingInstruction(target,
                                            data)

        default:
            throw XMLFormatter.Error.unexpectedNodeOutsideRootElement
        }
    }

    private mutating func _writeProcessingInstruction(_ target: String,
                                                      _ data: String?) throws(XMLFormatter.Error) {
        guard target.isXMLProcessingInstructionTarget
        else { throw XMLFormatter.Error.invalidProcessingInstructionTarget(target) }

        try _checkRepresentable(target)

        text += "<?\(target)"

        if let data {
            guard data.isXMLProcessingInstructionData
            else { throw XMLFormatter.Error.invalidProcessingInstructionData(target, data) }

            try _checkRepresentable(data)

            text += " \(data)"
        }

        text += "?>"
    }

    private mutating func _writeSystemID(_ systemID: String,
                                         _ name: String) throws(XMLFormatter.Error) {
        guard systemID.isXMLSystemID
        else { throw XMLFormatter.Error.invalidDocumentType(name) }

        try _checkRepresentable(systemID)

        let quote = systemID.contains("\"") ? "'" : "\""

        text += "\(quote)\(systemID)\(quote)"
    }

    private mutating func _writeText(_ value: String) throws(XMLFormatter.Error) {
        guard let escValue = value.escapedXMLText(repertoire)
        else { throw XMLFormatter.Error.invalidTextValue(value) }

        text += escValue
    }
}

// MARK: - Private Constants

private let xmlNamespaceURI = "http://www.w3.org/XML/1998/namespace"
