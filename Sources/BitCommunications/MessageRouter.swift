import Foundation
import BitCore
import Combine
import CoreBluetooth

public protocol MessageRouterDelegate: AnyObject {
    func messageRouter(_ router: MessageRouter, didReceive message: BitMessage)
}

public class MessageRouter {
    public weak var delegate: MessageRouterDelegate?
    private var transports: [Transport]
    private var cancellables = Set<AnyCancellable>()

    public init(transports: [Transport]) {
        self.transports = transports
        setupTransportDelegates()
    }

    private func setupTransportDelegates() {
        for i in 0..<transports.count {
            let wrapper = TransportDelegateWrapper(router: self)
            transports[i].delegate = wrapper
            transports[i].peerSnapshotPublisher
                .sink { [weak self] snapshots in
                    // Handle peer snapshots if needed
                }
                .store(in: &cancellables)
        }
    }

    public func sendMessage(_ content: String, mentions: [String]) {
        for transport in transports {
            transport.sendMessage(content, mentions: mentions)
        }
    }

    public func sendPrivateMessage(_ content: String, to peerID: PeerID, recipientNickname: String, messageID: String) {
        for transport in transports {
            if transport.isPeerReachable(peerID) {
                transport.sendPrivateMessage(content, to: peerID, recipientNickname: recipientNickname, messageID: messageID)
            }
        }
    }
}

// Wrapper to handle transport delegate calls
private class TransportDelegateWrapper: BitDelegate {
    weak var router: MessageRouter?

    init(router: MessageRouter) {
        self.router = router
    }

    func didReceiveMessage(_ message: BitMessage) {
        router?.delegate?.messageRouter(router!, didReceive: message)
    }

    func didConnectToPeer(_ peerID: PeerID) {
        // Handle if needed
    }

    func didDisconnectFromPeer(_ peerID: PeerID) {
        // Handle if needed
    }

    func didUpdatePeerList(_ peers: [PeerID]) {
        // Handle if needed
    }

    func didUpdateBluetoothState(_ state: CBManagerState) {
        // Handle if needed
    }

    func didReceivePublicMessage(from peerID: PeerID, nickname: String, content: String, timestamp: Date, messageID: String?) {
        // Handle if needed
    }
}