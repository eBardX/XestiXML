// © 2026 John Gary Pusey (see LICENSE.md)

internal import Foundation
internal import libxml2

// MARK: - Internal Functions

//  Drives libxml2’s SAX2 push parser over `data`, reporting events to `sink`;
//  returns `true` if the document is well-formed and the sink did not abort
//  the parse, `false` otherwise.
internal func saxParse(_ data: Data,
                       _ sink: SAXEventSink) -> Bool {
    _ = isInitialized

    var handler = xmlSAXHandler()

    handler.initialized = XML_SAX2_MAGIC
    handler.startElementNs = saxStartElementNs
    handler.endElementNs = saxEndElementNs
    handler.characters = saxCharacters
    handler.cdataBlock = saxCdataBlock
    handler.comment = saxComment
    handler.processingInstruction = saxProcessingInstruction
    handler.internalSubset = saxInternalSubset
    handler.externalSubset = saxExternalSubset
    handler.serror = saxError

    //  libxml2 keeps the handler pointer for the lifetime of the parser
    //  context, so the entire parse must run inside `withUnsafeMutablePointer`
    //  rather than merely the context creation.
    return withUnsafeMutablePointer(to: &handler) { handlerPtr in
        //  Passing NULL as the user data makes libxml2 set
        //  `ctxt->userData = ctxt`, so every callback can reach both the parser
        //  context and — via `_private` — the sink.
        guard let ctxt = xmlCreatePushParserCtxt(handlerPtr, nil, nil, 0, nil)
        else { return false }

        defer { xmlFreeParserCtxt(ctxt) }

        ctxt.pointee._private = Unmanaged.passUnretained(sink).toOpaque()

        xmlCtxtUseOptions(ctxt, options)

        return withExtendedLifetime(sink) {
            data.withUnsafeBytes { raw in
                if let base = raw.baseAddress,
                   !raw.isEmpty {
                    _ = xmlParseChunk(ctxt,
                                      base.assumingMemoryBound(to: CChar.self),
                                      Int32(raw.count),
                                      0)
                }

                _ = xmlParseChunk(ctxt, nil, 0, 1)
            }

            //  The XML declaration needs no SAX handler at all: libxml2 records
            //  it on the parser context, where it can be read once the parse
            //  has run to completion.
            sink.setDeclaration(_string(ctxt.pointee.version),
                                _string(ctxt.pointee.encoding),
                                ctxt.pointee.standalone)

            //  `xmlStopParser` leaves `wellFormed` set, so an abort can only be
            //  detected by our own flag.
            //
            //  `nsWellFormed` is a second flag because libxml2 keeps namespace
            //  defects out of `wellFormed` entirely. Checking it changes no
            //  outcome today — such a defect is reported through `serror` at
            //  `XML_ERR_ERROR`, and the sink has already latched a failure by
            //  the time this runs — but it costs nothing and does not depend on
            //  the severity libxml2 happens to assign. Nothing may reach here
            //  having silently dropped the namespace off a prefixed name.
            return ctxt.pointee.wellFormed != 0
                && ctxt.pointee.nsWellFormed != 0
                && !sink.shouldAbort
        }
    }
}

// MARK: - Private Constants

//  Swift initializes a global `let` exactly once, thread-safely.
private let isInitialized: Bool = {
    xmlInitParser()

    return true
}()

//  Every option NOT set here is unset deliberately:
//
//  - `XML_PARSE_NOENT` is the important one. Despite its name it does not
//    merely substitute entities, it turns on `replaceEntities`, which makes
//    libxml2 *fetch* the content of external entities — verified to read
//    `file:///etc/passwd` even with `XML_PARSE_NONET` set and
//    `XML_PARSE_DTDLOAD` unset. Setting it would open an XXE hole.
//  - `XML_PARSE_DTDLOAD` would fetch external DTD subsets.
//  - `XML_PARSE_NOBLANKS` aliases `ignorableWhitespace` onto `characters`.
//  - `XML_PARSE_NOCDATA` NULLs out `cdataBlock`.
//  - `XML_PARSE_HUGE` lifts the entity-expansion limits that defend against
//    billion-laughs attacks.
private let options = Int32(XML_PARSE_NONET.rawValue)
                    | Int32(XML_PARSE_NOERROR.rawValue)
                    | Int32(XML_PARSE_NOWARNING.rawValue)

// MARK: - Private Functions

private func _string(_ pointer: UnsafePointer<xmlChar>?) -> String? {
    pointer.map { String(cString: $0) }
}
