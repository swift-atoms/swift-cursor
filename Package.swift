// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "swift-cursor",
    platforms: [
        .macOS(.v27),
        .iOS(.v27),
        .tvOS(.v27),
        .watchOS(.v27),
        .visionOS(.v27),
    ],
    products: [
        .library(name: "Cursor", targets: ["Cursor"]),

        .library(name: "Cursor Foundation Integration", targets: ["Cursor Foundation Integration"]),
        .library(name: "Cursor Test Support", targets: ["Cursor Test Support"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/swift-atoms/swift-iterator.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-atoms/swift-checkpoint.git",
            branch: "main"
        ),
    ],
    targets: [
        .target(
            name: "Cursor",
            dependencies: [
                .product(name: "Iterator", package: "swift-iterator"),
                .product(name: "Checkpoint", package: "swift-checkpoint"),
            ],
            path: "Sources/Cursor"
        ),
        
        .target(
            name: "Cursor Foundation Integration",
            dependencies: [
                .target(name: "Cursor"),
            ],
            path: "Sources/Cursor Foundation Integration"
        ),
        .target(
            name: "Cursor Test Support",
            dependencies: [
                .target(name: "Cursor"),
            ],
            path: "Tests/Support"
        ),
        .testTarget(
            name: "Cursor Tests",
            dependencies: [
                .target(name: "Cursor"),
                .product(name: "Checkpoint Test Support", package: "swift-checkpoint"),
                .target(name: "Cursor Test Support"),
                .target(name: "Cursor Foundation Integration"),
            ],
            path: "Tests/Cursor Tests",
            resources: [.copy("Fixtures")]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets {
    target.swiftSettings = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("Lifetimes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
    ]
}
