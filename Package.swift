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
        .library(name: "TeatroRenderAPI", targets: ["TeatroRenderAPI"]),
        .library(name: "RenderAPI", targets: ["RenderAPI"]),
        .executable(name: "RenderCLI", targets: ["RenderCLI"]),
        .executable(name: "TeatroSamplerDemo", targets: ["TeatroSamplerDemo"]),
        .executable(name: "teatro-play", targets: ["TeatroPlay"]),
        // Demo preview app for the SDL3 + MIDI2 integration (stub-enabled)
        .executable(name: "TeatroPreviewDemo", targets: ["TeatroPreviewDemo"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
        .package(url: "https://github.com/swiftlang/swift-tools-support-core", from: "0.6.0"),
        .package(url: "https://github.com/Fountain-Coach/midi2", from: "0.3.0"),
        .package(url: "https://github.com/unrelentingtech/SwiftCBOR", from: "0.5.0")
    ],
    targets: [
        .target(
            name: "Teatro",
            dependencies: ["CCsound", "CFluidSynth", .product(name: "MIDI2", package: "MIDI2"), "SwiftCBOR"],
            path: "Sources",
            exclude: [
                "CLI",
                "TeatroSamplerDemo",
                "TeatroPlay",
                "TeatroPreviewDemo",
                "FountainCLI",
                "TeatroSDLBackend",
                "MIDIIntegration",
                "CCsound",
                "CFluidSynth",
                "MIDI/Teatro-Codex-Plan.md",
                "TeatroRenderAPI",
                "RenderAPI"
            ],
            resources: [
                .process("Audio/Resources")
            ],
            swiftSettings: [
                .unsafeFlags([
                    "-Xfrontend", "-strict-concurrency=complete",
                    "-Xfrontend", "-enable-actor-data-race-checks",
                    "-Xfrontend", "-warn-concurrency"
                ], .when(configuration: .debug))
            ],
            linkerSettings: [
                .linkedFramework("AVFoundation", .when(platforms: [.macOS]))
            ]
        ),
        // Internal SDL3 backend wrapper (currently stubbed unless SDL is available)
        .target(
            name: "TeatroSDLBackend",
            dependencies: [],
            path: "Sources/TeatroSDLBackend",
            swiftSettings: [
                .unsafeFlags([
                    "-Xfrontend", "-strict-concurrency=complete",
                    "-Xfrontend", "-enable-actor-data-race-checks",
                    "-Xfrontend", "-warn-concurrency"
                ], .when(configuration: .debug))
            ]
        ),
        // MIDI integration utilities that adapt MIDI2 usage for the preview
        .target(
            name: "MIDIIntegration",
            dependencies: ["Teatro", .product(name: "MIDI2", package: "MIDI2")],
            path: "Sources/MIDIIntegration",
            swiftSettings: [
                .unsafeFlags([
                    "-Xfrontend", "-strict-concurrency=complete",
                    "-Xfrontend", "-enable-actor-data-race-checks",
                    "-Xfrontend", "-warn-concurrency"
                ], .when(configuration: .debug))
            ]
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
        // Optional: separate CLI for preview command (kept minimal)
        .executableTarget(
            name: "FountainCLI",
            dependencies: [
                "Teatro",
                "TeatroRenderAPI",
                "TeatroSDLBackend",
                "MIDIIntegration",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            path: "Sources/FountainCLI"
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
        .executableTarget(
            name: "TeatroPlay",
            dependencies: [
                "Teatro",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            path: "Sources/TeatroPlay",
            swiftSettings: [
                .unsafeFlags([
                    "-parse-as-library",
                    "-Xfrontend", "-strict-concurrency=complete",
                    "-Xfrontend", "-enable-actor-data-race-checks",
                    "-Xfrontend", "-warn-concurrency"
                ], .when(configuration: .debug))
            ]
        ),
        .target(
            name: "TeatroRenderAPI",
            dependencies: ["Teatro", "TeatroSDLBackend"],
            path: "Sources/TeatroRenderAPI"
        ),
        .target(
            name: "RenderAPI",
            dependencies: ["Teatro", "TeatroRenderAPI"],
            path: "Sources/RenderAPI"
        ),
        // Demo preview executable used by the AGENTS.md entrypoint
        .executableTarget(
            name: "TeatroPreviewDemo",
            dependencies: [
                "Teatro",
                "TeatroRenderAPI",
                "TeatroSDLBackend",
                "MIDIIntegration"
            ],
            path: "Sources/TeatroPreviewDemo"
        ),
        .testTarget(
            name: "TeatroTests",
            dependencies: ["Teatro"],
            path: "Tests",
            exclude: ["StoryboardDSLTests", "MIDITests", "RendererFileTests", "SamplerTests", "CLI", "TeatroRenderAPITests", "RenderAPITests"],
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
            path: "Tests/SamplerTests",
            resources: [
                .copy("../../assets/sine.orc"),
                .copy("../../assets/example.sf2")
            ]
        ),
        .testTarget(
            name: "CLITests",
            dependencies: ["RenderCLI"],
            path: "Tests/CLI"
        ),
        .testTarget(
            name: "TeatroRenderAPITests",
            dependencies: ["TeatroRenderAPI"],
            path: "Tests/TeatroRenderAPITests",
            resources: [
                .process("__snapshots__")
            ]
        ),
        .testTarget(
            name: "RenderAPITests",
            dependencies: ["RenderAPI"],
            path: "Tests/RenderAPITests"
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
