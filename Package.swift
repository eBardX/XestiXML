// swift-tools-version:5.10

// © 2022–2024 John Gary Pusey (see LICENSE.md)

import PackageDescription

let swiftSettings: [SwiftSetting] = [.enableUpcomingFeature("BareSlashRegexLiterals"),
                                     .enableUpcomingFeature("ConciseMagicFile"),
                                     .enableUpcomingFeature("ExistentialAny"),
                                     .enableUpcomingFeature("ForwardTrailingClosures"),
                                     .enableUpcomingFeature("ImplicitOpenExistentials")]

let package = Package(name: "XestiXML",
                      platforms: [.iOS(.v15),
                                  .macOS(.v13)],
                      products: [.library(name: "XestiXML",
                                          targets: ["XestiXML"])],
                      dependencies: [.package(url: "https://github.com/eBardX/XestiTools.git",
                                              from: "3.0.0")],
                      targets: [.target(name: "XestiXML",
                                        dependencies: [.product(name: "XestiTools",
                                                                package: "XestiTools")],
                                        swiftSettings: swiftSettings)],
                      swiftLanguageVersions: [.version("5")])
