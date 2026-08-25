// © 2026 John Gary Pusey (see LICENSE.md)

import Testing
@testable import XestiXML

struct XMLDocumentTests {
}

// MARK: -

extension XMLDocumentTests {
    @Test
    func init_defaults() {
        let document = Test2Document(root: Test2Node(element: .root,
                                                     attributes: [:],
                                                     children: []))

        #expect(document.declaration == nil)
        #expect(document.documentType == nil)
        #expect(document.prolog.isEmpty)
        #expect(document.epilog.isEmpty)
        #expect(document.root.element == .root)
    }

    @Test
    func init_fullValues() {
        let document = Test2Document(declaration: XMLDeclaration(version: "1.1"),
                                     documentType: XMLDocumentType(name: "root"),
                                     prolog: [Test2Node(comment: " before ")],
                                     root: Test2Node(element: .root,
                                                     attributes: [:],
                                                     children: [Test2Node(text: "inside")]),
                                     epilog: [Test2Node(comment: " after ")])

        #expect(document.declaration?.version == "1.1")
        #expect(document.documentType?.name == "root")
        #expect(document.prolog.count == 1)
        #expect(document.root.value == "inside")
        #expect(document.epilog.count == 1)
    }

    //  The prolog and epilog are ordered, and each keeps the kind of node it was
    //  given rather than flattening everything into comments.
    @Test
    func init_prologAndEpilogRetainNodeOrderAndKind() {
        let document = Test2Document(prolog: [Test2Node(comment: " license "),
                                              Test2Node(processingInstruction: "xml-stylesheet",
                                                        data: "href=\"a.xsl\"")],
                                     root: Test2Node(element: .root,
                                                     attributes: [:],
                                                     children: []),
                                     epilog: [Test2Node(processingInstruction: "after")])

        #expect(document.prolog.first?.isComment == true)
        #expect(document.prolog.first?.comment == " license ")
        #expect(document.prolog.last?.isProcessingInstruction == true)
        #expect(document.prolog.last?.target == "xml-stylesheet")
        #expect(document.epilog.first?.target == "after")
    }
}
