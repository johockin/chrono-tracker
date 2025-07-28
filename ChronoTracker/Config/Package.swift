// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "ChronoTrackerConfig",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(name: "ChronoTracker Config", targets: ["ChronoTrackerConfig"])
    ],
    targets: [
        .executableTarget(
            name: "ChronoTrackerConfig",
            path: "ChronoTracker Config"
        )
    ]
)