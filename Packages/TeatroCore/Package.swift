// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "TeatroCore",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "TeatroCore", targets: ["TeatroCore"])
    ],
    dependencies: [
        .package(url: "https://github.com/Fountain-Coach/midi2", from: "0.3.0")
    ],
    targets: [
        .target(
            name: "TeatroCore",
            dependencies: [
                .product(name: "MIDI2", package: "midi2")
            ],
            path: "Sources/TeatroCore",
            exclude: ["MIDI/Teatro-Codex-Plan.md"],
            swiftSettings: [
                .unsafeFlags([
                    "-Xfrontend", "-strict-concurrency=complete",
                    "-Xfrontend", "-enable-actor-data-race-checks",
                    "-Xfrontend", "-warn-concurrency"
                ], .when(configuration: .debug))
            ]
        )
    ]
)
