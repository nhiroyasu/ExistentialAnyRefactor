// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ExistentialAnyRefactor",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        .executable(name: "existential-any-refactor", targets: ["ExistentialAnyRefactorExec"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax", from: "510.0.2"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "ExistentialAnyRefactor",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
            ]
        ),
        .testTarget(
            name: "ExistentialAnyRefactorTests",
            dependencies: [
                .target(name: "ExistentialAnyRefactor"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax")
            ]
        ),
        .target(
            name: "ExistentialTypeRetriever",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax")
            ]
        ),
        .testTarget(
            name: "ExistentialTypeRetrieverTests",
            dependencies: [
                .target(name: "ExistentialTypeRetriever"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax")
            ]
        ),
        .target(name: "Util"),
        .executableTarget(
            name: "ExistentialAnyRefactorExec",
            dependencies: [
                .target(name: "ExistentialAnyRefactor"),
                .target(name: "ExistentialTypeRetriever"),
                .target(name: "Util")
            ]
        )
    ]
)
