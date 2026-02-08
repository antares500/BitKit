import Foundation

// Basic identity types to avoid circular dependencies
public struct CryptographicIdentity {
    public let fingerprint: String
    public let publicKey: Data
    public var signingPublicKey: Data?
    public let firstSeen: Date
    public let lastHandshake: Date?
}

public struct SocialIdentity {
    public let fingerprint: String
    public var localPetname: String?
    public var claimedNickname: String
    public var trustLevel: String
    public var isFavorite: Bool
    public var isBlocked: Bool
    public var notes: String?
}

#if canImport(CoreBluetooth)
import CoreBluetooth
#endif

public protocol KeychainManagerProtocol {
    func getIdentityKey(forKey: String) -> Data?
    func saveIdentityKey(_ data: Data, forKey: String) -> Bool
    func deleteIdentityKey(forKey: String) -> Bool
    func save(key: String, data: Data, service: String, accessible: CFString?)
    func load(key: String, service: String) -> Data?
    func delete(key: String, service: String)
}
public protocol SecureIdentityStateManagerProtocol {
    // MARK: Secure Loading/Saving
    func forceSave()
    
    // MARK: Social Identity Management
    func getSocialIdentity(for fingerprint: String) -> SocialIdentity?
    
    // MARK: Cryptographic Identities
    func upsertCryptographicIdentity(fingerprint: String, noisePublicKey: Data, signingPublicKey: Data?, claimedNickname: String?)
    func getCryptoIdentitiesByPeerIDPrefix(_ peerID: PeerID) -> [CryptographicIdentity]
    func updateSocialIdentity(_ identity: SocialIdentity)
    
    // MARK: Favorites Management
    func getFavorites() -> Set<String>
    func setFavorite(_ fingerprint: String, isFavorite: Bool)
    func isFavorite(fingerprint: String) -> Bool
    
    // MARK: Blocked Users Management
    func isBlocked(fingerprint: String) -> Bool
    func setBlocked(_ fingerprint: String, isBlocked: Bool)
    
    // MARK: Geohash (Nostr) Blocking
    func isNostrBlocked(pubkeyHexLowercased: String) -> Bool
    func setNostrBlocked(_ pubkeyHexLowercased: String, isBlocked: Bool)
}
public protocol NostrIdentityBridge {
    func getCurrentNostrIdentity() throws -> String
}