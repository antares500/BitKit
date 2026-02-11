//
// IdentityModels.swift
// bitchatKit
//
// This is free and unencumbered software released into the public domain.
// For more information, see <https://unlicense.org>
//

import Foundation
import BitCore

// MARK: - Three-Layer Identity Model

/// Represents the ephemeral layer of identity - short-lived peer IDs that provide network privacy.
/// These IDs rotate periodically to prevent tracking while maintaining cryptographic relationships.
public struct EphemeralIdentity {
    public let peerID: PeerID          // 8 random bytes
    public let sessionStart: Date
    public var handshakeState: HandshakeState
}

public enum HandshakeState {
    case none
    case initiated
    case inProgress
    case completed(fingerprint: String)
    case failed(reason: String)
}

/// Represents the cryptographic layer of identity - the stable Noise Protocol static key pair.
/// This identity persists across ephemeral ID rotations and enables secure communication.
/// The fingerprint serves as the permanent identifier for a peer's cryptographic identity.
public struct CryptographicIdentity: Codable {
    public let fingerprint: String     // SHA256 of public key
    public let publicKey: Data         // Noise static public key
    // Optional Ed25519 signing public key (used to authenticate public messages)
    public var signingPublicKey: Data? = nil
    public let firstSeen: Date
    public let lastHandshake: Date?
}

/// Represents the social layer of identity - user-assigned names and trust relationships.
/// This layer provides human-friendly identification and relationship management.
/// All data in this layer is local-only and never transmitted over the network.
public struct SocialIdentity: Codable {
    public let fingerprint: String
    public var localPetname: String?   // User's name for this peer
    public var claimedNickname: String // What peer calls themselves
    public var trustLevel: TrustLevel
    public var isFavorite: Bool
    public var isBlocked: Bool
    public var notes: String?
}

public enum TrustLevel: String, Codable {
    case unknown = "unknown"
    case casual = "casual"
    case trusted = "trusted"
    case verified = "verified"
}