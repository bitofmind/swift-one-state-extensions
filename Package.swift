// swift-tools-version:5.7

import PackageDescription

#if swift(>=5.7)
let swiftSettings: [SwiftSetting] = []//[SwiftSetting.unsafeFlags(["-Xfrontend", "-warn-concurrency"])]
#else
let swiftSettings: [SwiftSetting] = []
#endif

let package = Package(
    name: "swift-one-state-extensions",
    platforms: [
        .iOS(.v14),
        .macOS(.v11),
    ],
    products: [
        .library(name: "OneStateExtensions", targets: ["OneStateExtensions"]),
    ],
    dependencies: [
        .package(url: "https://github.com/bitofmind/swift-one-state", from: "0.13.5"),
        .package(url: "https://github.com/pointfreeco/swift-case-paths", from: "0.11.0"),
        .package(url: "https://github.com/pointfreeco/swift-identified-collections", from: "0.6.0"),
    ],
    targets: [
        .target(
            name: "OneStateExtensions",
            dependencies: [
                .product(name: "OneState", package: "swift-one-state"),
                .product(name: "CasePaths", package: "swift-case-paths"),
                .product(name: "IdentifiedCollections", package: "swift-identified-collections"),
            ],
            swiftSettings: swiftSettings
        ),
    ]
)
