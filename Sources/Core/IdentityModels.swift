import Foundation

// MARK: - Three-Layer Identity Model

/// Represents the ephemeral layer of identity - short-lived peer IDs that provide network privacy.
/// These IDs rotate periodically to prevent tracking while maintaining cryptographic relationships.
public struct EphemeralIdentity {
    public let peerID: PeerID          // 8 random bytes
    public let sessionStart: Date
    public var handshakeState: HandshakeState

    /// Public initializer so other modules (targets) can construct EphemeralIdentity
    public init(peerID: PeerID, sessionStart: Date, handshakeState: HandshakeState) {
        self.peerID = peerID
        self.sessionStart = sessionStart
        self.handshakeState = handshakeState
    }
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

    /// Public initializer for usage across module boundaries
    public init(fingerprint: String, publicKey: Data, signingPublicKey: Data? = nil, firstSeen: Date = Date(), lastHandshake: Date? = nil) {
        self.fingerprint = fingerprint
        self.publicKey = publicKey
        self.signingPublicKey = signingPublicKey
        self.firstSeen = firstSeen
        self.lastHandshake = lastHandshake
    }
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

    /// Public initializer for cross-module construction
    public init(fingerprint: String, localPetname: String? = nil, claimedNickname: String = "", trustLevel: TrustLevel = .unknown, isFavorite: Bool = false, isBlocked: Bool = false, notes: String? = nil) {
        self.fingerprint = fingerprint
        self.localPetname = localPetname
        self.claimedNickname = claimedNickname
        self.trustLevel = trustLevel
        self.isFavorite = isFavorite
        self.isBlocked = isBlocked
        self.notes = notes
    }
}

public enum TrustLevel: String, Codable {
    case unknown = "unknown"
    case casual = "casual"
    case trusted = "trusted"
    case verified = "verified"
}

// MARK: - Identity Cache

/// Persistent storage for identity mappings and relationships.
/// Provides efficient lookup between fingerprints, nicknames, and social identities.
/// Storage is optional and controlled by user privacy settings.
public struct IdentityCache: Codable {
    // Fingerprint -> Social mapping
    public var socialIdentities: [String: SocialIdentity] = [:]
    
    // Nickname -> [Fingerprints] reverse index
    // Multiple fingerprints can claim same nickname
    public var nicknameIndex: [String: Set<String>] = [:]
    
    // Verified fingerprints (cryptographic proof)
    public var verifiedFingerprints: Set<String> = []
    
    // Last interaction timestamps (privacy: optional)
    public var lastInteractions: [String: Date] = [:] 
    
    // Blocked Nostr pubkeys (lowercased hex) for geohash chats
    public var blockedNostrPubkeys: Set<String> = []
    
    // Schema version for future migrations
    public var version: Int = 1

    /// Public zero-argument initializer (used by other modules)
    public init() {}
}
