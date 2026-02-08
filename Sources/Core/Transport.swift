import Foundation
import Combine

public protocol Transport {
    var delegate: BitchatDelegate? { get set }
    var peerEventsDelegate: TransportPeerEventsDelegate? { get set }
    var peerSnapshotPublisher: AnyPublisher<[TransportPeerSnapshot], Never> { get }
    var myPeerID: PeerID { get }
    var myNickname: String { get set }
    func startServices()
    func stopServices()
    func emergencyDisconnectAll()
    func isPeerConnected(_ peerID: PeerID) -> Bool
    func isPeerReachable(_ peerID: PeerID) -> Bool
    func peerNickname(peerID: PeerID) -> String?
    func getPeerNicknames() -> [PeerID: String]
    func getFingerprint(for peerID: PeerID) -> String?
    func getNoiseSessionState(for peerID: PeerID) -> LazyHandshakeState
    func triggerHandshake(with peerID: PeerID)
    func getNoiseService() -> NoiseEncryptionService
    func sendMessage(_ content: String, mentions: [String])
    func sendPrivateMessage(_ content: String, to peerID: PeerID, recipientNickname: String, messageID: String)
    func sendReadReceipt(_ receipt: ReadReceipt, to peerID: PeerID)
    func sendDeliveryAck(for messageID: String, to peerID: PeerID)
    func sendFavoriteNotification(to peerID: PeerID, isFavorite: Bool)
    func sendBroadcastAnnounce()
}
public struct TransportPeerSnapshot: Equatable, Hashable {
    public let peerID: PeerID
    public let nickname: String
    public let isConnected: Bool
    public let noisePublicKey: Data?
    public let lastSeen: Date

    public init(peerID: PeerID, nickname: String, isConnected: Bool, noisePublicKey: Data?, lastSeen: Date) {
        self.peerID = peerID
        self.nickname = nickname
        self.isConnected = isConnected
        self.noisePublicKey = noisePublicKey
        self.lastSeen = lastSeen
    }
}

public protocol TransportPeerEventsDelegate: AnyObject {
    @MainActor func didUpdatePeerSnapshots(_ peers: [TransportPeerSnapshot])
}