// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MarkdownBrowser",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "MarkdownBrowser",
            targets: ["MarkdownBrowser"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-markdown.git", from: "0.3.0")
    ],
    targets: [
        .executableTarget(
            name: "MarkdownBrowser",
            dependencies: [
                .product(name: "Markdown", package: "swift-markdown")
            ],
            path: "MarkdownBrowser",
            exclude: ["Assets.xcassets", "Preview Content", "MarkdownBrowser.entitlements"]
        ),
        .testTarget(
            name: "MarkdownBrowserTests",
            dependencies: ["MarkdownBrowser"],
            path: "MarkdownBrowserTests"
        ),
    ]
)