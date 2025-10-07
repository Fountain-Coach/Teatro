// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "teatro",
    platforms: [.macOS(.v14)],
    products: [
        // Umbrella library re-exporting modular targets for backward compatibility
        .library(name: "Teatro", targets: ["Teatro"]),
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
        // Local modular packages
        .package(path: "Packages/TeatroCore"),
        .package(path: "Packages/TeatroAudio"),
        .package(path: "Packages/TeatroGUI"),
        .package(path: "Packages/TeatroTelemetry"),
        // ScoreKit for music model + utilities
        .package(url: "https://github.com/Fountain-Coach/ScoreKit.git", branch: "main")
    ],
    targets: [
        // No local Core/Audio/GUI/Telemetry targets; use local packages

        // MARK: - Umbrella `Teatro` target re-exporting modules for backward compatibility
        .target(
            name: "Teatro",
            dependencies: [
                .product(name: "TeatroCore", package: "TeatroCore"),
                .product(name: "TeatroAudio", package: "TeatroAudio"),
                .product(name: "TeatroGUI", package: "TeatroGUI"),
                .product(name: "TeatroTelemetry", package: "TeatroTelemetry")
            ],
            path: "Sources/Teatro",
            exclude: [],
            swiftSettings: [
                .unsafeFlags([
                    "-Xfrontend", "-strict-concurrency=complete",
                    "-Xfrontend", "-enable-actor-data-race-checks",
                    "-Xfrontend", "-warn-concurrency"
                ], .when(configuration: .debug))
            ]
        ),
        // MARK: - ScoreKit renderer plugin (SVG)
        .target(
            name: "TeatroScoreKitRenderer",
            dependencies: [
                .product(name: "TeatroCore", package: "TeatroCore"),
                .product(name: "ScoreKit", package: "ScoreKit"),
                .product(name: "ScoreKitUI", package: "ScoreKit")
            ],
            path: "Sources/TeatroScoreKitRenderer"
        ),

        // MARK: - CLI and API layers (unchanged dependencies on umbrella)
        .executableTarget(
            name: "RenderCLI",
            dependencies: [
                "Teatro",
                // Register ScoreKit renderers via module import
                "TeatroScoreKitRenderer",
                .product(name: "ScoreKit", package: "ScoreKit"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "SwiftToolsSupport", package: "swift-tools-support-core")
            ],
            path: "Sources/CLI"
        ),
        // Simple A/B compare CLI for lily ↔︎ ScoreKit outputs with RMSE
        .executableTarget(
            name: "CompareCLI",
            dependencies: [
                "Teatro",
                "TeatroScoreKitRenderer",
                .product(name: "ScoreKit", package: "ScoreKit"),
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            path: "Sources/CompareCLI"
        ),
        .executableTarget(
            name: "FountainCLI",
            dependencies: [
                "Teatro",
                "TeatroRenderAPI",
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
            dependencies: ["Teatro", .product(name: "ScoreKit", package: "ScoreKit")],
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
                
            ],
            path: "Sources/TeatroPreviewDemo"
        ),
        // macOS SwiftUI app for interactive ScoreKit vs Lily comparison (RMSE/heatmap)
        .executableTarget(
            name: "ScoreKitCompareApp",
            dependencies: [
                .product(name: "ScoreKit", package: "ScoreKit"),
                "TeatroRenderAPI",
                "TeatroScoreKitRenderer"
            ],
            path: "Sources/ScoreKitCompareApp"
        ),
        // Headless A4 page generator for fixtures (ScoreKit vs Lily)
        .executableTarget(
            name: "ScoreKitA4",
            dependencies: [
                .product(name: "ScoreKit", package: "ScoreKit"),
                .product(name: "ScoreKitUI", package: "ScoreKit"),
                "TeatroScoreKitRenderer"
            ],
            path: "Sources/ScoreKitA4"
        ),
        // macOS SwiftUI app for interactive ScoreKit preview
        .executableTarget(
            name: "ScoreKitPreviewApp",
            dependencies: [
                .product(name: "ScoreKit", package: "ScoreKit")
            ],
            path: "Sources/ScoreKitPreviewApp"
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
        )
    ]
)

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
