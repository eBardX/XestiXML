# ``XestiXML``

@Metadata {
    @PageColor(blue)
}

XML tools.

## Overview

The XestiXML framework provides a collection of XML tools for Swift, built on
top of `libxml2`. Parsing and formatting revolve around two small pipeline
types, each generic over your own type-safe element and attribute types:

 Stage  | Type              | Input → Output
:-----  |:----              |:--------------
 Parse  | ``XMLParser``     | `Data` → ``XMLDocument``
 Format | ``XMLFormatter``  | ``XMLDocument`` → `Data`

An ``XMLDocument`` wraps a tree of ``XMLNode``s — elements, text, comments, and
processing instructions — together with everything that surrounds the root
element: the XML declaration, the document type declaration, and any prolog or
epilog content. Elements and attributes are reported as a local name paired
with a namespace URI, never a prefix, so namespace handling is unambiguous in
both directions.

```swift
import Foundation
import XestiXML

enum Element: String, XMLElement {
    case greeting
}

enum Attribute: String, XMLAttribute {
    case lang
}

let data = "<greeting lang=\"en\">Hello!</greeting>".data(using: .utf8)!

let document = try XMLParser<Element, Attribute>().parse(data)
let output   = try XMLFormatter<Element, Attribute>(options: .pretty).format(document)
```

See ``XMLParser`` and ``XMLFormatter`` for the full details of what is, and is
not, represented — and for the handful of documented limitations of each.

## Topics

### Parsing and formatting

- ``XMLParser``
- ``XMLFormatter``

### Document model

- ``XMLDocument``
- ``XMLNode``
- ``XMLDeclaration``
- ``XMLDocumentType``

### Type-safe names

- ``XMLElement``
- ``XMLAttribute``

### Formatting options

- ``XMLFormatter/Options``
- ``XMLFormatter/Namespace``
