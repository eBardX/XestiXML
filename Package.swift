// swift-tools-version: 6.2

// © 2022–2026 John Gary Pusey (see LICENSE.md)

import PackageDescription

let package = Package(name: "XestiXML",
                      platforms: [.iOS(.v16),
                                  .macOS(.v14)],
                      products: [.library(name: "XestiXML",
                                          targets: ["XestiXML"])],
                      dependencies: [.package(url: "https://github.com/swiftlang/swift-docc-plugin.git",
                                              .upToNextMajor(from: "1.1.0")),
                                     .package(url: "https://github.com/eBardX/XestiTools.git",
                                              .upToNextMajor(from: "6.0.0"))],
                      targets: [.target(name: "XestiXML",
                                        dependencies: [.product(name: "XestiTools",
                                                                package: "XestiTools")])],
                      swiftLanguageModes: [.v6])

let swiftSettings: [SwiftSetting] = [.defaultIsolation(nil),
                                     .enableUpcomingFeature("ExistentialAny")]

for target in package.targets {
    var settings = target.swiftSettings ?? []

    settings.append(contentsOf: swiftSettings)

    target.swiftSettings = settings
}
