// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "swift-one-state-extensions",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
    ],
    products: [
        .library(name: "OneStateExtensions", targets: ["OneStateExtensions"]),
    ],
    dependencies: [
        .package(url: "https://github.com/bitofmind/swift-one-state", from: "0.2.0"),
        .package(url: "https://github.com/pointfreeco/swift-custom-dump", from: "0.3.0"),
        .package(url: "https://github.com/pointfreeco/swift-case-paths", from: "0.7.0"),
        .package(url: "https://github.com/pointfreeco/swift-identified-collections", from: "0.3.2"),
        .package(url: "https://github.com/pointfreeco/xctest-dynamic-overlay", from: "0.2.1"),
    ],
    targets: [
        .target(
            name: "OneStateExtensions",
            dependencies: [
                .product(name: "OneState", package: "swift-one-state"),
                .product(name: "CasePaths", package: "swift-case-paths"),
                .product(name: "IdentifiedCollections", package: "swift-identified-collections"),
                .product(name: "CustomDump", package: "swift-custom-dump"),
                .product(name: "XCTestDynamicOverlay", package: "xctest-dynamic-overlay"),
            ]
        ),
    ]
)
