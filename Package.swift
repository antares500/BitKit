// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "bitkit",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "BitCore", targets: ["BitCore"]),
        .library(name: "BitTor", targets: ["BitTor"]),
        .library(name: "BitLogger", targets: ["BitLogger"]),
        .library(name: "BitState", targets: ["BitState"]),
        .library(name: "BitMedia", targets: ["BitMedia"]),
        .library(name: "BitTransport", targets: ["BitTransport"]),
        .library(name: "BitCommunications", targets: ["BitCommunications"]),
        .library(name: "BitIdentity", targets: ["BitIdentity"]),
        .library(name: "BitGeo", targets: ["BitGeo"]),
        .library(name: "BitRouting", targets: ["BitRouting"]),
        .library(name: "BitChatGroup", targets: ["BitChatGroup"]),
        .library(name: "BitReliability", targets: ["BitReliability"]),
        .library(name: "BitAnalytics", targets: ["BitAnalytics"]),
        .library(name: "BitKit", targets: ["BitKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/21-DOT-DEV/swift-secp256k1", exact: "0.21.1"),
    ],
    targets: [
        .target(name: "BitCore",            dependencies: ["BitLogger"],            path: "Sources/Core"),
        .target(name: "BitTor",             dependencies: ["BitCore", "BitLogger"], path: "Sources/Tor"),
        .target(name: "BitLogger",          dependencies: [],                       path: "Sources/BitLogger"),
        .target(name: "BitState",           dependencies: ["BitCore", "BitLogger"], path: "Sources/State"),
        .target(name: "BitMedia",           dependencies: ["BitCore"],              path: "Sources/Media"),
        .target(name: "BitTransport",       dependencies: ["BitCore", "BitState", "BitLogger", "BitGeo", .product(name: "P256K", package: "swift-secp256k1")], path: "Sources/Transport"),
        .target(name: "BitCommunications",  dependencies: ["BitCore", "BitLogger"], path: "Sources/Communications"),
        .target(name: "BitIdentity",        dependencies: ["BitCore"],              path: "Sources/Identity"),
        .target(name: "BitGeo",             dependencies: ["BitCore", "BitLogger"], path: "Sources/Geo"),
        .target(name: "BitRouting",         dependencies: ["BitCore"],              path: "Sources/Routing"),
        .target(name: "BitChatGroup",       dependencies: ["BitCore"],              path: "Sources/ChatGroup"),
        .target(name: "BitReliability",     dependencies: ["BitCore", "BitState"],      path: "Sources/ReliabilityExtended"),
        .target(name: "BitAnalytics",       dependencies: ["BitCommunications"],    path: "Sources/Analytics"),
        .target(name: "BitKit",             dependencies: ["BitCore", "BitTransport", "BitGeo", "BitState", "BitMedia", "BitCommunications", "BitChatGroup", "BitReliability", "BitAnalytics"], path: "Sources/Kit"),
        .testTarget(name: "BitCoreTests", dependencies: ["BitCore", "BitState", "BitMedia"], path: "Tests"),
    ]
)