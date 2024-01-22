// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Shoppy",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Shoppy",
            targets: ["Shoppy"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Shopify/mobile-buy-sdk-ios.git", from: "11.2.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Shoppy",
            dependencies: [
                .product(name: "Buy", package: "mobile-buy-sdk-ios"),
                .product(name: "Pay", package: "mobile-buy-sdk-ios")
            ]
        ),
        .testTarget(
            name: "ShoppyTests",
            dependencies: ["Shoppy"]),
    ]
)
