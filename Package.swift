// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "bitchatKit",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "bitchatKit", targets: ["bitchatKit"]),  // Full
        .library(name: "BitchatCore", targets: ["BitchatCore"]),
        .library(name: "BitchatTor", targets: ["BitchatTor"]),
        .library(name: "BitchatState", targets: ["BitchatState"]),
        .library(name: "BitchatMedia", targets: ["BitchatMedia"]),
        .library(name: "BitchatBLE", targets: ["BitchatBLE"]),
        .library(name: "BitchatNostr", targets: ["BitchatNostr"]),
        .library(name: "BitchatGeo", targets: ["BitchatGeo"]),
        .library(name: "BitchatCommunications", targets: ["BitchatCommunications"]),
        .library(name: "BitchatIdentity", targets: ["BitchatIdentity"]),
        .library(name: "BitchatUtils", targets: ["BitchatUtils"]),
        .library(name: "BitchatRouting", targets: ["BitchatRouting"]),
    ],
    dependencies: [
        .package(path: "../bitchat/localPackages/BitLogger"),
        .package(path: "../bitchat/localPackages/Arti"),
        .package(url: "https://github.com/21-DOT-DEV/swift-secp256k1", exact: "0.21.1"),
    ],
    targets: [
        .target(name: "BitchatCore", dependencies: ["BitLogger"], path: "Sources/Core"),
        .target(name: "BitchatTor", dependencies: ["BitLogger", .product(name: "Tor", package: "Arti")], path: "Sources/Tor"),  // Binary XCFramework Arti
        .target(name: "BitchatState", dependencies: ["BitchatCore"], path: "Sources/State"),
        .target(name: "bitchatKit", dependencies: ["BitchatCore", "BitchatState"], path: "Sources/BitchatCommunications"),
        .target(name: "BitchatMedia", dependencies: ["BitchatCore"], path: "Sources/Media"),
        .target(name: "BitchatBLE", dependencies: ["BitchatCore", "BitchatState"], path: "Sources/BLE"),
        .target(name: "BitchatNostr", dependencies: ["BitchatCore", "BitchatState", "BitchatGeo", .product(name: "P256K", package: "swift-secp256k1")], path: "Sources/Nostr"),
        .target(name: "BitchatGeo", dependencies: ["BitchatCore", "BitchatState"], path: "Sources/Geo"),
        .target(name: "BitchatCommunications", dependencies: ["BitchatCore"], path: "Sources/Communications"),
        .target(name: "BitchatIdentity", dependencies: ["BitchatCore"], path: "Sources/Identity"),
        .target(name: "BitchatUtils", dependencies: ["BitchatCore"], path: "Sources/Utils"),
        .target(name: "BitchatRouting", dependencies: ["BitchatCore"], path: "Sources/Routing"),
    ]
)