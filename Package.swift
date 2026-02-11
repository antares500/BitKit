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
        .library(name: "BitBLE", targets: ["BitBLE"]),
        .library(name: "BitNostr", targets: ["BitNostr"]),
        .library(name: "BitCommunications", targets: ["BitCommunications"]),
        .library(name: "BitIdentity", targets: ["BitIdentity"]),
        .library(name: "BitGeo", targets: ["BitGeo"]),
        .library(name: "BitRouting", targets: ["BitRouting"]),
        .library(name: "BitChat", targets: ["BitChat"]),
        .library(name: "BitReliability", targets: ["BitReliability"]),
        .library(name: "BitSync", targets: ["BitSync"]),
        .library(name: "BitVerification", targets: ["BitVerification"]),
    ],
    dependencies: [
        .package(url: "https://github.com/21-DOT-DEV/swift-secp256k1", exact: "0.21.1"),
    ],
    targets: [
        .target(name: "BitCore", dependencies: ["BitLogger"], path: "Sources/Core"),
        .target(name: "BitTor", dependencies: ["BitCore", "BitLogger"], path: "Sources/Tor"),
        .target(name: "BitLogger", dependencies: [], path: "Sources/BitLogger"),
        .target(name: "BitState", dependencies: ["BitCore", "BitLogger"], path: "Sources/State"),
        .target(name: "BitMedia", dependencies: ["BitCore"], path: "Sources/Media"),
        .target(name: "BitBLE", dependencies: ["BitCore", "BitState"], path: "Sources/BLE"),
        .target(name: "BitNostr", dependencies: ["BitCore", "BitState", "BitLogger", "BitGeo", .product(name: "P256K", package: "swift-secp256k1")], path: "Sources/Nostr"),
        .target(name: "BitCommunications", dependencies: ["BitCore", "BitLogger"], path: "Sources/BitCommunications"),
        .target(name: "BitIdentity", dependencies: ["BitCore"], path: "Sources/Identity"),
        .target(name: "BitGeo", dependencies: ["BitCore", "BitTor", "BitLogger"], path: "Sources/Geo"),
        .target(name: "BitRouting", dependencies: ["BitCore"], path: "Sources/Routing"),
        .target(name: "BitChat", dependencies: ["BitCore"], path: "Sources/Chat"),
        .target(name: "BitReliability", dependencies: ["BitCore"], path: "Sources/Reliability"),
        .target(name: "BitSync", dependencies: ["BitCore"], path: "Sources/Sync"),
        .target(name: "BitVerification", dependencies: ["BitCore"], path: "Sources/Verification"),
    ]
)