// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
import libxml2
import Testing

//  Asserts that `data` is a well-formed XML document, according to libxml2
//  rather than to `XMLParser`.
//
//  Every formatter test funnels its output through `text(_:)`, which calls this
//  function, so each one is checked against an implementation that shares no
//  code with the thing under test. `XMLParser` is deliberately lenient about a
//  few constructs it cannot represent, and round-tripping through it therefore
//  cannot prove that what the formatter wrote is XML at all.
func expectWellFormed(_ data: Data,
                      _ sourceLocation: SourceLocation) {
    _ = isInitialized

    guard let ctxt = xmlNewParserCtxt()
    else {
        Issue.record("unable to create a libxml2 parser context",
                     sourceLocation: sourceLocation)

        return
    }

    defer { xmlFreeParserCtxt(ctxt) }

    let doc: xmlDocPtr? = data.withUnsafeBytes { raw in
        guard let base = raw.baseAddress,
              !raw.isEmpty
        else { return nil }

        return xmlCtxtReadMemory(ctxt,
                                 base.assumingMemoryBound(to: CChar.self),
                                 Int32(raw.count),
                                 nil,
                                 nil,
                                 options)
    }

    defer {
        if let doc {
            xmlFreeDoc(doc)
        }
    }

    //  `nsWellFormed` matters at least as much as `wellFormed` here. libxml2
    //  keeps namespace defects — an undeclared prefix, above all — out of
    //  `wellFormed` entirely, and an undeclared prefix is exactly what a
    //  mistake in `NamespaceTable` would produce.
    guard doc == nil
          || ctxt.pointee.wellFormed == 0
          || ctxt.pointee.nsWellFormed == 0
    else { return }

    let error = ctxt.pointee.lastError
    let reason = (error.message.map { String(cString: $0) } ?? "")
        .trimmingCharacters(in: .whitespacesAndNewlines)

    Issue.record("""
                 formatter output is not well-formed XML: \
                 \(reason.isEmpty ? "libxml2 error \(error.code)" : reason)

                 \(String(bytes: data, encoding: .utf8) ?? "\(data)")
                 """,
                 sourceLocation: sourceLocation)
}

// MARK: - Private Constants

//  Swift initializes a global `let` exactly once, thread-safely.
private let isInitialized: Bool = {
    xmlInitParser()

    return true
}()

//  The same posture `SAXParser` adopts: no entity substitution and no external
//  fetching of any kind, so a document type declaration naming a system
//  identifier is read but never resolved. `XML_PARSE_NOERROR` and
//  `XML_PARSE_NOWARNING` only suppress the report to stderr — the error is
//  still recorded on the context, which is where it is read from.
private let options = Int32(XML_PARSE_NONET.rawValue)
                    | Int32(XML_PARSE_NOERROR.rawValue)
                    | Int32(XML_PARSE_NOWARNING.rawValue)
