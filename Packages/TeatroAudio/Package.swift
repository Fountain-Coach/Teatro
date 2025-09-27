// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "TeatroAudio",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "TeatroAudio", targets: ["TeatroAudio"])
    ],
    dependencies: [
        .package(path: "../TeatroCore")
    ],
    targets: [
        .target(
            name: "TeatroAudio",
            dependencies: [
                .product(name: "TeatroCore", package: "TeatroCore"),
                "CCsound",
                "CFluidSynth"
            ],
            path: "Sources/TeatroAudio",
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

