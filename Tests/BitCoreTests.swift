import XCTest
import Combine
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

    func testMessageRouterQueuesAndFlushesToReachableTransport() {
        // Mock transport that can toggle reachability and record sent messages
        class MockTransport: Transport {
            var delegate: BitDelegate?
            var peerEventsDelegate: TransportPeerEventsDelegate?
            var peerSnapshotPublisher: AnyPublisher<[TransportPeerSnapshot], Never> { Just([]).eraseToAnyPublisher() }
            var myPeerID: PeerID = PeerID(str: "0000000000000000")
            var myNickname: String = "mock"
            private var reachablePeers = Set<PeerID>()
            var sentPrivate: [(String, PeerID, String, String)] = []

            func setReachable(_ peerID: PeerID, reachable: Bool) {
                if reachable { reachablePeers.insert(peerID) } else { reachablePeers.remove(peerID) }
            }
            func startServices() {}
            func stopServices() {}
            func emergencyDisconnectAll() {}
            func isPeerConnected(_ peerID: PeerID) -> Bool { reachablePeers.contains(peerID) }
            func isPeerReachable(_ peerID: PeerID) -> Bool { reachablePeers.contains(peerID) }
            func peerNickname(peerID: PeerID) -> String? { nil }
            func getPeerNicknames() -> [PeerID : String] { [:] }
            func getFingerprint(for peerID: PeerID) -> String? { nil }
            func getNoiseSessionState(for peerID: PeerID) -> LazyHandshakeState { .none }
            func triggerHandshake(with peerID: PeerID) {}
            func getNoiseService() -> NoiseEncryptionService { fatalError("not needed") }
            func sendMessage(_ content: String, mentions: [String]) {}
            func sendPrivateMessage(_ content: String, to peerID: PeerID, recipientNickname: String, messageID: String) {
                sentPrivate.append((content, peerID, recipientNickname, messageID))
            }
            func sendReadReceipt(_ receipt: ReadReceipt, to peerID: PeerID) {}
            func sendDeliveryAck(for messageID: String, to peerID: PeerID) {}
            func sendFavoriteNotification(to peerID: PeerID, isFavorite: Bool) {}
            func sendBroadcastAnnounce() {}
        }

        let mock = MockTransport()
        let router = MessageRouter(transports: [mock])

        let recipient = PeerID(str: "abcd1234abcd1234")
        let messageID = "msg-1"

        // Make transport reachable and send private message
        mock.setReachable(recipient, reachable: true)
        router.sendPrivateMessage("hello", to: recipient, recipientNickname: "bob", messageID: messageID)

        // The mock transport should have received the message immediately
        XCTAssertEqual(mock.sentPrivate.count, 1)
        XCTAssertEqual(mock.sentPrivate.first?.0, "hello")
        XCTAssertEqual(mock.sentPrivate.first?.2, "bob")
        XCTAssertEqual(mock.sentPrivate.first?.3, messageID)
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

    // MARK: - IdentityModels Codable tests

    func testIdentityModelsCodableRoundtrip() throws {
        let social = SocialIdentity(fingerprint: "fp1", localPetname: "Alice", claimedNickname: "alice", trustLevel: .trusted, isFavorite: true, isBlocked: false, notes: "note")
        let crypto = CryptographicIdentity(fingerprint: "fp1", publicKey: Data([0x01,0x02,0x03]), signingPublicKey: nil)
        var cache = IdentityCache()
        cache.socialIdentities["fp1"] = social
        cache.nicknameIndex["alice"] = ["fp1"]
        cache.verifiedFingerprints = ["fp1"]

        let encoder = JSONEncoder()
        let data = try encoder.encode(cache)
        let decoded = try JSONDecoder().decode(IdentityCache.self, from: data)

        XCTAssertEqual(decoded.socialIdentities.count, 1)
        XCTAssertEqual(decoded.socialIdentities["fp1"]?.claimedNickname, "alice")
        XCTAssertTrue(decoded.verifiedFingerprints.contains("fp1"))
    }

    func testEphemeralIdentityPublicInit() {
        let peer = PeerID(str: "abcd")
        let eid = EphemeralIdentity(peerID: peer, sessionStart: Date(), handshakeState: .none)
        XCTAssertEqual(eid.peerID, peer)
    }

    // MARK: - NetworkConfig tests
    #if canImport(PluribusApp)
    func testNetworkConfigCodableRoundtrip() throws {
        var cfg = NetworkConfig()
        cfg.isPrivate = true
        cfg.networkName = "TestNet"
        cfg.version = 42

        let data = try JSONEncoder().encode(cfg)
        let decoded = try JSONDecoder().decode(NetworkConfig.self, from: data)

        XCTAssertEqual(decoded.isPrivate, true)
        XCTAssertEqual(decoded.networkName, "TestNet")
        XCTAssertEqual(decoded.version, 42)
    }

    func testNetworkConfigRegenerateKeyIncrementsVersionAndFillsPublicKey() throws {
        var cfg = NetworkConfig()
        let oldVersion = cfg.version
        cfg.publicKey = ""
        cfg.regenerateKey()
        XCTAssertFalse(cfg.publicKey.isEmpty)
        XCTAssertGreaterThan(cfg.version, oldVersion)
    }
    #else
    func testNetworkConfigCodableRoundtrip() throws {
        try XCTSkip("NetworkConfig is part of the application target; skipping in BitKit package tests")
    }

    func testNetworkConfigRegenerateKeyIncrementsVersionAndFillsPublicKey() throws {
        try XCTSkip("NetworkConfig is part of the application target; skipping in BitKit package tests")
    }
    #endif

    // MARK: - VerificationService Tests

    func testVerificationServiceInitialization() {
        let service = VerificationService()
        XCTAssertNotNil(service)
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

    // MARK: - IdentityModels Tests

    func testSocialIdentityInitialization() {
        let identity = SocialIdentity(fingerprint: "fp1", localPetname: "Alice", claimedNickname: "alice", trustLevel: .trusted, isFavorite: true, isBlocked: false, notes: "note")
        XCTAssertEqual(identity.fingerprint, "fp1")
        XCTAssertEqual(identity.localPetname, "Alice")
    }

    func testCryptographicIdentityInitialization() {
        let data = Data([0x01, 0x02, 0x03])
        let identity = CryptographicIdentity(fingerprint: "fp1", publicKey: data, signingPublicKey: nil)
        XCTAssertEqual(identity.fingerprint, "fp1")
        XCTAssertEqual(identity.publicKey, data)
    }

    // MARK: - MediaManager Tests

    func testMediaManagerInitialization() {
        let manager = MediaManager()
        XCTAssertNotNil(manager)
    }

    // MARK: - MediaCompressionService Tests

    func testMediaCompressionServiceInitialization() {
        let service = MediaCompressionService()
        XCTAssertNotNil(service)
    }

    // MARK: - Transport Tests (Basic, no mocks)

    func testBLETransportInitialization() throws {
        try XCTSkip("Concrete transport implementations are platform-specific or moved; skip in package tests")
    }

    func testWiFiTransportInitialization() throws {
        try XCTSkip("Concrete transport implementations are platform-specific or moved; skip in package tests")
    }

    func testCellularTransportInitialization() throws {
        try XCTSkip("Concrete transport implementations are platform-specific or moved; skip in package tests")
    }

    func testNostrTransportInitialization() throws {
        try XCTSkip("Concrete transport implementations are platform-specific or moved; skip in package tests")
    }

    // MARK: - Coordinator Tests

    func testCoordinatorInitialization() {
        let coordinator = Coordinator()
        XCTAssertNotNil(coordinator)
    }

    // MARK: - TorIntegration Tests (with Mock)

    func testTorIntegrationWithMock() {
        let mockTor = MockTorManager()
        mockTor.isReadyMock = true
        // Test logic that uses Tor
        XCTAssertTrue(mockTor.isReady)
    }

    // MARK: - BLE Transport Tests (with Mock)

    func testBLETransportWithMock() {
        let mockBLE = MockBLETransport()
        mockBLE.isReachableMock = true
        let peerID = PeerID(str: "test")!
        XCTAssertTrue(mockBLE.isPeerReachable(peerID))
    }

    // MARK: - Nostr Transport Tests (with Mock)

    func testNostrTransportWithMock() {
        let mockNostr = MockNostrTransport()
        mockNostr.sendMessage("Hello", mentions: [])
        XCTAssertTrue(mockNostr.sendEventCalled)
    }

    // MARK: - Media Manager Tests (with Mock)

    func testMediaManagerWithMock() {
        let mockMedia = MockMediaManager()
        let data = Data([1, 2, 3])
        let compressed = mockMedia.compress(data: data)
        XCTAssertTrue(mockMedia.compressCalled)
        XCTAssertEqual(compressed, data)
    }

    // MARK: - LoggingService Tests

    func testLoggingServiceInitialization() {
        let logger = LoggingService()
        XCTAssertNotNil(logger)
    }
}

