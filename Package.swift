// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "STARKit",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        .library(name: "STARCore", targets: ["STARCore"]),
        .library(name: "STARUI", targets: ["STARUI"]),
        .library(name: "STAREvents", targets: ["STAREvents"]),
        .library(name: "STARNetworking", targets: ["STARNetworking"]),
        .library(name: "STARPayments", targets: ["STARPayments"])
    ],
    dependencies: [
        .package(url: "https://github.com/onevcat/Kingfisher.git", from: "8.0.0"),
        .package(url: "https://github.com/AppsFlyerSDK/AppsFlyerFramework-Static", .upToNextMajor(from: "7.0.0")),
        .package(url: "https://github.com/mixpanel/mixpanel-swift.git", .upToNextMajor(from: "6.4.1")),
        .package(url: "https://github.com/RevenueCat/purchases-ios.git", .upToNextMajor(from: "5.80.0"))
    ],
    targets: [
        .target(name: "STARCore"),
        .target(
            name: "STARUI",
            dependencies: [
                "STARCore",
                .product(name: "Kingfisher", package: "Kingfisher")
            ]
        ),
        .target(
            name: "STAREvents",
            dependencies: [
                .product(name: "AppsFlyerLib-Static", package: "AppsFlyerFramework-Static"),
                .product(name: "Mixpanel", package: "mixpanel-swift")
            ]
        ),
        .target(name: "STARNetworking"),
        .target(
            name: "STARPayments",
            dependencies: [
                "STAREvents",
                .product(name: "RevenueCat", package: "purchases-ios")
            ]
        )
    ],
    swiftLanguageModes: [.v6]
)
