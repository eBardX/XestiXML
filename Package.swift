// swift-tools-version: 6.3

// © 2022–2026 John Gary Pusey (see LICENSE.md)

import PackageDescription

let swiftSettings: [SwiftSetting] = [.defaultIsolation(nil),
                                     .enableUpcomingFeature("ExistentialAny"),
                                     .enableUpcomingFeature("ImmutableWeakCaptures"),
                                     .enableUpcomingFeature("InferIsolatedConformances"),
                                     .enableUpcomingFeature("InternalImportsByDefault"),
                                     .enableUpcomingFeature("MemberImportVisibility"),
                                     .enableUpcomingFeature("NonisolatedNonsendingByDefault")]

let package = Package(name: "XestiXML",
                      platforms: [.iOS(.v16),
                                  .macOS(.v14)],
                      products: [.library(name: "XestiXML",
                                          targets: ["XestiXML"])],
                      dependencies: [.package(url: "https://github.com/eBardX/XestiTools.git",
                                              .upToNextMajor(from: "9.1.0"))],
                      targets: [.target(name: "XestiXML",
                                        dependencies: [.product(name: "XestiTools",
                                                                package: "XestiTools")],
                                        swiftSettings: swiftSettings),
                                .testTarget(name: "XestiXMLTests",
                                            dependencies: [.target(name: "XestiXML")],
                                            swiftSettings: swiftSettings)],
                      swiftLanguageModes: [.v6])
