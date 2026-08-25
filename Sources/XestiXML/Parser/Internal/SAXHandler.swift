// © 2026 John Gary Pusey (see LICENSE.md)

internal import libxml2

private import Foundation

// MARK: - Internal Constants

internal let saxCdataBlock: cdataBlockSAXFunc = { ctx, chars, length in
    guard let (sink, _) = _resolve(ctx)
    else { return }

    sink.appendText(_string(chars, length))
}

internal let saxCharacters: charactersSAXFunc = { ctx, chars, length in
    guard let (sink, _) = _resolve(ctx)
    else { return }

    sink.appendText(_string(chars, length))
}

internal let saxComment: commentSAXFunc = { ctx, chars in
    guard let (sink, _) = _resolve(ctx)
    else { return }

    sink.appendComment(_string(chars) ?? "")
}

internal let saxEndElementNs: endElementNsSAX2Func = { ctx, localName, _, uri in
    guard let (sink, _) = _resolve(ctx)
    else { return }

    sink.endElement(_string(localName) ?? "",
                    _string(uri))
}

internal let saxError: xmlStructuredErrorFunc = { ctx, error in
    guard let (sink, _) = _resolve(ctx),
          let error
    else { return }

    sink.handleError(LibXMLError(error.pointee))
}

//  libxml2 has no "end of internal subset" callback, but it calls
//  `externalSubset` at exactly that point — after the last declaration of the
//  internal subset and before anything that follows the `<!DOCTYPE>`. Verified
//  for every shape of document type declaration: bare, empty subset, populated
//  subset, and external identifier.
//
//  The external subset itself is never loaded (see `SAXParser.swift`), so
//  nothing is fetched by installing this.
internal let saxExternalSubset: externalSubsetSAXFunc = { ctx, _, _, _ in
    guard let (sink, _) = _resolve(ctx)
    else { return }

    sink.endInternalSubset()
}

//  Reports the header of a document type declaration. libxml2 calls this for
//  *any* `<!DOCTYPE>`, whether or not an internal subset follows, and supplies
//  the external identifier without ever resolving it.
internal let saxInternalSubset: internalSubsetSAXFunc = { ctx, name, publicID, systemID in
    guard let (sink, _) = _resolve(ctx)
    else { return }

    sink.setDocumentType(_string(name) ?? "",
                         _string(publicID),
                         _string(systemID))
}

internal let saxProcessingInstruction: processingInstructionSAXFunc = { ctx, target, data in
    guard let (sink, _) = _resolve(ctx)
    else { return }

    sink.appendProcessingInstruction(_string(target) ?? "",
                                     _string(data))
}

internal let saxStartElementNs: startElementNsSAX2Func = { ctx, localName, _, uri, _, _, attrCount, _, attrs in
    guard let (sink, ctxt) = _resolve(ctx)
    else { return }

    var attributes: [SAXAttribute] = []

    if let attrs {
        attributes.reserveCapacity(Int(attrCount))

        //
        // The array is a flat run of 5-tuples: local name, prefix, URI, and the
        // half-open bounds of the value. The prefix is skipped deliberately —
        // see `SAXAttribute`.
        //
        for index in 0..<Int(attrCount) {
            let base = index * 5

            attributes.append(SAXAttribute(_string(attrs[base]) ?? "",
                                           _string(attrs[base + 2]),
                                           _attributeValue(from: attrs[base + 3],
                                                           to: attrs[base + 4])))
        }
    }

    sink.startElement(_string(localName) ?? "",
                      _string(uri),
                      attributes)

    if sink.shouldAbort {
        sink.handleAbort(Int(xmlSAX2GetLineNumber(ctx)),
                         Int(xmlSAX2GetColumnNumber(ctx)))

        xmlStopParser(ctxt)
    }
}

// MARK: - Private Functions

//  Reads a normalized attribute value.
//
//  The value is the half-open range [value_start, value_end); it is *not*
//  NUL-terminated, so it must never be read with `String(cString:)`.
//
//  libxml2 has already resolved character and predefined entity references,
//  but — because entity substitution is off (see `SAXParser.swift`) — it
//  re-escapes a resolved ampersand as `&#38;` so that the value could be
//  re-parsed unambiguously. That is the only escape it emits here, and both
//  `&amp;` and `&#38;` in the source produce it, so undoing it is lossless.
private func _attributeValue(from start: UnsafePointer<xmlChar>?,
                             to end: UnsafePointer<xmlChar>?) -> String {
    let value = _string(from: start,
                        to: end)

    guard value.contains("&")
    else { return value }

    return value.replacingOccurrences(of: "&#38;",
                                      with: "&")
}

//  Every SAX2 callback receives the `xmlParserCtxt` itself as its user data
//  (see `saxParse(_:_:)`), and the sink rides in the context's `_private`
//  field.
private func _resolve(_ ctx: UnsafeMutableRawPointer?) -> (SAXEventSink, xmlParserCtxtPtr)? {
    guard let ctx
    else { return nil }

    let ctxt = xmlParserCtxtPtr(OpaquePointer(ctx))

    guard let priv = ctxt.pointee._private
    else { return nil }

    return (Unmanaged<SAXEventSink>.fromOpaque(priv).takeUnretainedValue(),
            ctxt)
}

private func _string(_ pointer: UnsafePointer<xmlChar>?) -> String? {
    pointer.map { String(cString: $0) }
}

private func _string(_ pointer: UnsafePointer<xmlChar>?,
                     _ length: Int32) -> String {
    guard let pointer,
          length > 0
    else { return "" }

    //  These are raw libxml2 buffers, not `Data`, and libxml2 always delivers
    //  UTF-8; a non-failable decode is what a C callback needs.
    // swiftlint:disable:next optional_data_string_conversion
    return String(decoding: UnsafeBufferPointer(start: pointer,
                                                count: Int(length)),
                  as: UTF8.self)
}

private func _string(from start: UnsafePointer<xmlChar>?,
                     to end: UnsafePointer<xmlChar>?) -> String {
    guard let start,
          let end,
          end > start
    else { return "" }

    //  These are raw libxml2 buffers, not `Data`, and libxml2 always delivers
    //  UTF-8; a non-failable decode is what a C callback needs.
    // swiftlint:disable:next optional_data_string_conversion
    return String(decoding: UnsafeBufferPointer(start: start,
                                                count: end - start),
                  as: UTF8.self)
}
