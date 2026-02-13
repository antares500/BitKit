import Foundation

// Identity model types are defined in `IdentityModels.swift` to avoid duplication
// and keep a single canonical source for Codable/data-model definitions.
// (Struct declarations removed from this file to prevent symbol collisions.)

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
    func getBlockedNostrPubkeys() -> Set<String>
    
    // MARK: Ephemeral Session Management
    func registerEphemeralSession(peerID: PeerID, handshakeState: HandshakeState)
    func updateHandshakeState(peerID: PeerID, state: HandshakeState)
    
    // MARK: Cleanup
    func clearAllIdentityData()
    func removeEphemeralSession(peerID: PeerID)
    
    // MARK: Verification
    func setVerified(fingerprint: String, verified: Bool)
    func isVerified(fingerprint: String) -> Bool
    func getVerifiedFingerprints() -> Set<String>
    
    // MARK: Backup and Restore
    func exportBackup() throws -> Data
    func importBackup(_ data: Data) throws
    func generateInitialIdentity() throws -> String
    
    // MARK: Nostr Identity
    func getCurrentNostrIdentity() throws -> String
}

public protocol NostrIdentityBridge {
    func getCurrentNostrIdentity() throws -> String
}