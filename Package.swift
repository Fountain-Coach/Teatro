// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "teatro",
    platforms: [.macOS(.v14)],
    products: [
        .library(
            name: "Teatro",
            targets: ["Teatro"]
        ),
        .executable(name: "RenderCLI", targets: ["RenderCLI"]),
        .executable(name: "TeatroSamplerDemo", targets: ["TeatroSamplerDemo"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
        .package(url: "https://github.com/swiftlang/swift-tools-support-core", from: "0.6.0")
    ],
    targets: [
        .target(
            name: "Teatro",
            dependencies: ["CCsound", "CFluidSynth"],
            path: "Sources",
            exclude: ["CLI", "TeatroSamplerDemo", "CCsound", "CFluidSynth"]
        ),
        .executableTarget(
            name: "RenderCLI",
            dependencies: [
                "Teatro",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "SwiftToolsSupport", package: "swift-tools-support-core")
            ],
            path: "Sources/CLI"
        ),
        .executableTarget(
            name: "TeatroSamplerDemo",
            dependencies: ["Teatro"],
            path: "Sources/TeatroSamplerDemo",
            resources: [
                .copy("../../assets/sine.orc"),
                .copy("../../assets/example.sf2")
            ]
        ),
        .testTarget(
            name: "TeatroTests",
            dependencies: ["Teatro"],
            path: "Tests",
            exclude: ["StoryboardDSLTests", "MIDITests", "RendererFileTests", "SamplerTests", "CLI"],
            resources: [
                .process("Fixtures")
            ]
        ),
        .testTarget(
            name: "StoryboardDSLTests",
            dependencies: ["Teatro"],
            path: "Tests/StoryboardDSLTests"
        ),
        .testTarget(
            name: "MIDITests",
            dependencies: ["Teatro"],
            path: "Tests/MIDITests"
        ),
        .testTarget(
            name: "RendererFileTests",
            dependencies: ["Teatro"],
            path: "Tests/RendererFileTests"
        ),
        .testTarget(
            name: "SamplerTests",
            dependencies: ["Teatro"],
            path: "Tests/SamplerTests"
        ),
        .testTarget(
            name: "CLITests",
            dependencies: ["RenderCLI"],
            path: "Tests/CLI"
        ),
        .target(
            name: "CCsound",
            path: "Sources/CCsound",
            publicHeadersPath: "."
        ),
        .target(
            name: "CFluidSynth",
            path: "Sources/CFluidSynth",
            publicHeadersPath: "."
        )
    ]
)

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.

