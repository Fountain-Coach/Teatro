// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "TeatroTelemetry",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "TeatroTelemetry", targets: ["TeatroTelemetry"]) 
    ],
    dependencies: [
        .package(url: "https://github.com/unrelentingtech/SwiftCBOR", from: "0.5.0"),
        .package(path: "../TeatroCore")
    ],
    targets: [
        .target(
            name: "TeatroTelemetry",
            dependencies: [
                "SwiftCBOR",
                .product(name: "TeatroCore", package: "TeatroCore")
            ],
            path: "Sources/TeatroTelemetry",
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

