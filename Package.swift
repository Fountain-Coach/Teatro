// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "teatro",
    platforms: [.macOS(.v14)],
    products: [
        // Umbrella library re-exporting modular targets for backward compatibility
        .library(name: "Teatro", targets: ["Teatro"]),
        // New modular libraries
        .library(name: "TeatroCore", targets: ["TeatroCore"]),
        .library(name: "TeatroAudio", targets: ["TeatroAudio"]),
        .library(name: "TeatroGUI", targets: ["TeatroGUI"]),
        .library(name: "TeatroTelemetry", targets: ["TeatroTelemetry"]),
        // Existing API layers and tools
        .library(name: "TeatroRenderAPI", targets: ["TeatroRenderAPI"]),
        .library(name: "RenderAPI", targets: ["RenderAPI"]),
        .executable(name: "RenderCLI", targets: ["RenderCLI"]),
        .executable(name: "TeatroSamplerDemo", targets: ["TeatroSamplerDemo"]),
        .executable(name: "teatro-play", targets: ["TeatroPlay"]),
        .executable(name: "TeatroPreviewDemo", targets: ["TeatroPreviewDemo"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
        .package(url: "https://github.com/swiftlang/swift-tools-support-core", from: "0.6.0"),
        .package(url: "https://github.com/Fountain-Coach/midi2", from: "0.3.0"),
        .package(url: "https://github.com/unrelentingtech/SwiftCBOR", from: "0.5.0")
    ],
    targets: [
        // MARK: - Core (single target for now; GUI/Audio/Streaming excluded)
        .target(
            name: "TeatroCore",
            dependencies: [
                .product(name: "MIDI2", package: "MIDI2"),
                "SwiftCBOR"
            ],
            path: "Sources",
            exclude: [
                "Audio",
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
                "RenderAPI",
                "ViewCore/Streaming",
                "TeatroGUI",
                "TeatroTelemetry",
                // keep Teatro/Core in Core, exclude only umbrella file
                "Teatro/Umbrella.swift"
            ],
            resources: [
                // Exclude Audio resources from core; handled by TeatroAudio
            ],
            swiftSettings: [
                .unsafeFlags([
                    "-Xfrontend", "-strict-concurrency=complete",
                    "-Xfrontend", "-enable-actor-data-race-checks",
                    "-Xfrontend", "-warn-concurrency"
                ], .when(configuration: .debug))
            ]
        ),

        // MARK: - Audio
        .target(
            name: "TeatroAudio",
            dependencies: ["TeatroCore", "CCsound", "CFluidSynth"],
            path: "Sources/Audio",
            resources: [
                .process("Resources")
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

        // MARK: - Telemetry (placeholder aggregate target)
        .target(
            name: "TeatroTelemetry",
            dependencies: [],
            path: "Sources/TeatroTelemetry"
        ),

        // MARK: - GUI (SDL backend + SwiftUI overlay stubs)
        .target(
            name: "TeatroGUIViews",
            dependencies: [],
            path: "Sources/ViewCore/Streaming"
        ),
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
        .target(
            name: "MIDIIntegration",
            dependencies: ["TeatroCore", .product(name: "MIDI2", package: "MIDI2")],
            path: "Sources/MIDIIntegration",
            swiftSettings: [
                .unsafeFlags([
                    "-Xfrontend", "-strict-concurrency=complete",
                    "-Xfrontend", "-enable-actor-data-race-checks",
                    "-Xfrontend", "-warn-concurrency"
                ], .when(configuration: .debug))
            ]
        ),
        .target(
            name: "TeatroGUI",
            dependencies: ["TeatroSDLBackend", "MIDIIntegration", "TeatroGUIViews", "TeatroCore", "TeatroTelemetry"],
            path: "Sources/TeatroGUI"
        ),

        // MARK: - Umbrella `Teatro` target re-exporting modules for backward compatibility
        .target(
            name: "Teatro",
            dependencies: ["TeatroCore", "TeatroAudio", "TeatroGUI", "TeatroTelemetry"],
            path: "Sources/Teatro",
            exclude: ["Core"],
            swiftSettings: [
                .unsafeFlags([
                    "-Xfrontend", "-strict-concurrency=complete",
                    "-Xfrontend", "-enable-actor-data-race-checks",
                    "-Xfrontend", "-warn-concurrency"
                ], .when(configuration: .debug))
            ]
        ),

        // MARK: - CLI and API layers (unchanged dependencies on umbrella)
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

        // MARK: - Tests
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

        // MARK: - C targets
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
