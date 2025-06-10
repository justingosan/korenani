// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "korenani",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "korenani",
            targets: ["korenani"]
        ),
    ],
    dependencies: [
        // Add your dependencies here
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.2"),
        // Example:
        // .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.8.0"),
        // .package(url: "https://github.com/apple/swift-crypto.git", from: "3.0.0"),
    ],
    targets: [
        .target(
            name: "korenani",
            dependencies: [
                // Reference your dependencies here
                "KeychainAccess",
                // Example:
                // "Alamofire",
                // .product(name: "Crypto", package: "swift-crypto"),
            ],
            path: ".",
            exclude: [
                "build.log",
                "App/Info.plist",
                "korenani.xcodeproj"
            ],
            sources: [
                "App/AppDelegate.swift",
                "App/KoreNaniApp.swift",
                "Core",
                "Features",
                "UI"
            ],
            resources: [
                .process("Resources")
            ]
        ),
    ]
)
