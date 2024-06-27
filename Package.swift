// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "StreamUI",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(name: "StreamUI", targets: ["StreamUI"]),
        .executable(name: "CLIExample", targets: ["CLIExample"]),
        .library(name: "VideoViews", targets: ["VideoViews"]),
        .executable(name: "GenerateTemplate", targets: ["GenerateTemplate"]),

    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.4.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.4"),
        .package(url: "https://github.com/shogo4405/HaishinKit.swift.git", from: "1.9.0"),
        .package(url: "https://github.com/stencilproject/Stencil.git", from: "0.15.1"),
        .package(url: "https://github.com/pointfreeco/swift-clocks.git", from: "1.0.2"),
        .package(url: "https://github.com/kean/Nuke.git", from: "12.7.3"),
        .package(url: "https://github.com/vapor/console-kit.git", from: "4.14.3"),

    ],
    targets: [
        .target(
            name: "StreamUI",
            dependencies: [
                .product(name: "HaishinKit", package: "HaishinKit.swift"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Clocks", package: "swift-clocks"),
                .product(name: "Nuke", package: "Nuke"),
                .product(name: "ConsoleKit", package: "console-kit"),
            ],
            path: "Sources/StreamUI",
            resources: [
                .process("Resources"),
            ]),
        .testTarget(
            name: "StreamUITests",
            dependencies: ["StreamUI"]),

        .executableTarget(
            name: "CLIExample",
            dependencies: [
                "StreamUI",
                "VideoViews",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Examples/CLIExample"),

        .target(
            name: "VideoViews",
            dependencies: [
                "StreamUI",
            ],
            path: "Examples/VideoViews"),

        .executableTarget(name: "GenerateTemplate", dependencies: [
            .product(name: "Stencil", package: "Stencil"),
            .product(name: "ArgumentParser", package: "swift-argument-parser"),
            .product(name: "Logging", package: "swift-log"),
        ],
        path: "Scripts/GenerateTemplate",
        resources: [
            .process("Templates"),
        ]),

    ])
