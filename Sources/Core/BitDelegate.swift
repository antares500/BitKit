//
// BitDelegate.swift
// bitchat
//
// This is free and unencumbered software released into the public domain.
// For more information, see <https://unlicense.org>
//

import Foundation

#if canImport(CoreBluetooth)
import CoreBluetooth
#endif

/// Delegate protocol for receiving Bitchat events
public protocol BitDelegate: AnyObject {
    func didReceiveMessage(_ message: BitMessage)
    func didConnectToPeer(_ peerID: PeerID)
    func didDisconnectFromPeer(_ peerID: PeerID)
    func didUpdatePeerList(_ peers: [PeerID])

    // Optional method to check if a fingerprint belongs to a favorite peer
    func isFavorite(fingerprint: String) -> Bool

    func didUpdateMessageDeliveryStatus(_ messageID: String, status: DeliveryStatus)

    // Low-level events for better separation of concerns
    func didReceiveNoisePayload(from peerID: PeerID, type: NoisePayloadType, payload: Data, timestamp: Date)

    // Bluetooth state updates for user notifications
    func didUpdateBluetoothState(_ state: CBManagerState)
    func didReceivePublicMessage(from peerID: PeerID, nickname: String, content: String, timestamp: Date, messageID: String?)
}

// Provide default implementation to make it effectively optional
public extension BitDelegate {
    func isFavorite(fingerprint: String) -> Bool {
        return false
    }

    func didUpdateMessageDeliveryStatus(_ messageID: String, status: DeliveryStatus) {
        // Default empty implementation
    }

    func didReceiveNoisePayload(from peerID: PeerID, type: NoisePayloadType, payload: Data, timestamp: Date) {
        // Default empty implementation
    }

    func didReceivePublicMessage(from peerID: PeerID, nickname: String, content: String, timestamp: Date, messageID: String?) {
        // Default empty implementation
    }
}