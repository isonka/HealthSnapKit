// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "HealthSnapKit",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "HealthSnapKit", targets: ["HealthSnapKit"]),
    ],
    targets: [
        .target(
            name: "HealthSnapKit",
            dependencies: [],
            swiftSettings: [
                .unsafeFlags(["-strict-concurrency=complete"]),
            ]
        ),
        .testTarget(
            name: "HealthSnapKitTests",
            dependencies: ["HealthSnapKit"],
            swiftSettings: [
                .unsafeFlags(["-strict-concurrency=complete"]),
            ]
        ),
    ]
)
