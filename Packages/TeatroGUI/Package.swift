// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "TeatroGUI",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "TeatroGUI", targets: ["TeatroGUI"]) 
    ],
    dependencies: [
        .package(path: "../TeatroCore")
    ],
    targets: [
        .target(
            name: "TeatroGUI",
            dependencies: [
                .product(name: "TeatroCore", package: "TeatroCore")
            ],
            path: "Sources/TeatroGUI",
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

