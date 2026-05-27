// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "OnboardingKit",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(name: "OnboardingKit", targets: ["OnboardingKit"])
    ],
    targets: [
        .target(
            name: "OnboardingKit",
            path: "Sources/OnboardingKit"
        )
    ]
)
