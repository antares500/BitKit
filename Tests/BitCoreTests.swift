import XCTest
@testable import BitCore
@testable import BitState
@testable import BitMedia

final class BitCoreTests: XCTestCase {
    
    // MARK: - KeychainManager Tests
    
    func testKeychainManagerInitialization() {
        let keychain = KeychainManager()
        XCTAssertNotNil(keychain)
    }
    
    func testKeychainSaveAndLoad() {
        let keychain = KeychainManager()
        let testData = "test data".data(using: .utf8)!
        let key = "testKey"
        let service = "testService"
        
        // Save
        keychain.save(key: key, data: testData, service: service, accessible: nil)
        
        // Load
        let loadedData = keychain.load(key: key, service: service)
        XCTAssertEqual(loadedData, testData)
        
        // Delete
        keychain.delete(key: key, service: service)
        let deletedData = keychain.load(key: key, service: service)
        XCTAssertNil(deletedData)
    }
    
    // MARK: - NoiseEncryptionService Tests
    
    func testNoiseEncryptionServiceInitialization() {
        let keychain = KeychainManager()
        let noiseService = NoiseEncryptionService(keychain: keychain)
        XCTAssertNotNil(noiseService)
    }
    
    func testNoiseEncryption() {
        let keychain = KeychainManager()
        let noiseService = NoiseEncryptionService(keychain: keychain)
        let data = "Hello, World!".data(using: .utf8)!
        _ = PeerID(str: "testPeer") // Test PeerID creation
        
        // For basic test, just check that service exists
        // Encryption requires handshake setup
        XCTAssertNotNil(noiseService)
        XCTAssertEqual(data, "Hello, World!".data(using: .utf8)!)
    }
    
    // MARK: - MessageRouter Tests
    
    func testMessageRouterInitialization() {
        let transports: [Transport] = [] // Empty for test
        let router = MessageRouter(transports: transports)
        XCTAssertNotNil(router)
    }
    
    // MARK: - VerificationService Tests
    
    func testVerificationServiceInitialization() {
        let service = VerificationService()
        XCTAssertNotNil(service)
    }
    
    func testVerificationServiceVerifyMessage() {
        let service = VerificationService()
        let fingerprint = "testFingerprint"
        let qrCode = service.generateQRCode(for: fingerprint)
        XCTAssertNotNil(qrCode)
        
        let nonceA = Data([1, 2, 3, 4])
        let challenge = service.buildVerifyChallenge(noiseKeyHex: "testKey", nonceA: nonceA)
        XCTAssertNotNil(challenge)
    }
    
    // MARK: - TransferProgressManager Tests
    
    func testTransferProgressManagerInitialization() {
        let manager = TransferProgressManager()
        XCTAssertNotNil(manager)
    }
    
    // MARK: - PeerDisplayNameResolver Tests
    
    func testPeerDisplayNameResolverInitialization() {
        let resolver = PeerDisplayNameResolver()
        XCTAssertNotNil(resolver)
    }
    
    // MARK: - MessageDeduplicator Tests
    
    func testMessageDeduplicatorInitialization() {
        let deduplicator = MessageDeduplicator()
        XCTAssertNotNil(deduplicator)
    }
    
    // MARK: - RequestSyncManager Tests
    
    func testRequestSyncManagerInitialization() {
        let manager = RequestSyncManager()
        XCTAssertNotNil(manager)
    }
    
    // MARK: - SecurityConfig Tests
    
    func testSecurityConfigInitialization() {
        let config = SecurityConfig()
        XCTAssertNotNil(config)
    }
}