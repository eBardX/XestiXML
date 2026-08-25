# XestiXML

XML tools.

## <a name="overview">Overview</a>

The XestiXML framework provides a collection of XML tools for Swift, built on
top of `libxml2`. Parsing and formatting revolve around two small pipeline
types, each generic over your own type-safe element and attribute types:

 Stage  | Type             | Input → Output
:-----  |:----             |:--------------
 Parse  | `XMLParser`      | `Data` → `XMLDocument`
 Format | `XMLFormatter`   | `XMLDocument` → `Data`

An `XMLDocument` wraps a tree of `XMLNode`s — elements, text, comments, and
processing instructions — together with everything that surrounds the root
element: the XML declaration, the document type declaration, and any prolog or
epilog content. Elements and attributes are reported as a local name paired
with a namespace URI, never a prefix, so namespace handling is unambiguous in
both directions.

## <a name="requirements">Requirements</a>

* iOS 16.0+ / macOS 14.0+
* Swift 6 language mode

## <a name="installation">Installation</a>

### <a name="spm_installation">Swift Package Manager</a>

XestiXML is distributed exclusively through the [Swift Package Manager][spm].

To add XestiXML to a Swift package, add it to the `dependencies` in your
`Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/eBardX/XestiXML.git",
             .upToNextMajor(from: "5.0.0"))
]
```

Then add `XestiXML` to the dependencies of any target that uses it:

```swift
.target(name: "MyTarget",
        dependencies: [.product(name: "XestiXML",
                                package: "XestiXML")])
```

To add XestiXML to an Xcode project, choose **File ▸ Add Package Dependencies…**
and enter the repository URL:

```
https://github.com/eBardX/XestiXML.git
```

## <a name="quick_start">Quick Start</a>

Define your own element and attribute types — enums conforming to
`XMLElement` and `XMLAttribute` are the simplest option — then parse, walk, and
format an XML document:

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

// 1. Parse XML bytes into a typed node tree.
let document = try XMLParser<Element, Attribute>().parse(data)

document.root.element   // .greeting
document.root.value     // "Hello!"

// 2. Format the tree back to XML bytes.
let output = try XMLFormatter<Element, Attribute>(options: .pretty).format(document)
```

An element or attribute name your type doesn't recognize fails parsing with a
descriptive error rather than being silently dropped.

## <a name="documentation">Documentation</a>

Every public declaration carries a DocC comment; `XMLParser` and
`XMLFormatter` in particular describe their behavior — and limitations — in
detail.

## <a name="reference_documentation">Reference Documentation</a>

Full [reference documentation][refdoc] is available courtesy of [DocC][docc].

## <a name="credits">Credits</a>

John Gary Pusey (ebardx@gmail.com)

## <a name="license">License</a>

XestiXML is available under [the MIT license][license].

[docc]:     https://www.swift.org/documentation/docc/
[license]:  https://github.com/eBardX/XestiXML/blob/main/LICENSE.md
[refdoc]:   https://eBardX.github.io/xesti-packages-docs/documentation/xestixml
[spm]:      https://swift.org/package-manager/
