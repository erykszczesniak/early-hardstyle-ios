// swift-tools-version:6.0
import PackageDescription

/// Local multi-module package for Early Hardstyle.
/// Module boundaries mirror the app architecture: Features depend on
/// DesignSystem/Services/Core, and everything depends on protocols, not concretions.
let package = Package(
    name: "EarlyHardstyleKit",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(name: "Core", targets: ["Core"]),
        .library(name: "Services", targets: ["Services"]),
        .library(name: "DesignSystem", targets: ["DesignSystem"]),
        .library(name: "Features", targets: ["Features"])
    ],
    dependencies: [
        // Google's official wrapper around the YouTube iframe player — handles
        // the embedder verification (origin/referer) that a hand-rolled
        // WKWebView embed fails (YouTube error 152).
        .package(url: "https://github.com/youtube/youtube-ios-player-helper", from: "1.0.4")
    ],
    targets: [
        // MARK: Core — models, telemetry protocols, shared primitives.

        .target(
            name: "Core",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),

        // MARK: Services — catalog/favourites/player services (protocols + impls + mocks).

        .target(
            name: "Services",
            dependencies: ["Core"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),

        // MARK: DesignSystem — tokens, components, motion modifiers.

        .target(
            name: "DesignSystem",
            dependencies: ["Core"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),

        // MARK: Features — screen Views + ViewModels.

        .target(
            name: "Features",
            dependencies: [
                "Core",
                "Services",
                "DesignSystem",
                .product(name: "YouTubeiOSPlayerHelper", package: "youtube-ios-player-helper")
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),

        // MARK: Tests

        .testTarget(
            name: "CoreTests",
            dependencies: ["Core"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "ServicesTests",
            dependencies: ["Services"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "DesignSystemTests",
            dependencies: ["DesignSystem"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "FeaturesTests",
            dependencies: ["Features"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
