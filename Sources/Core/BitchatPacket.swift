// BitchatPacket.swift - Impl de WHITEPAPER (v2 con route)
import Foundation

public enum MessageType: UInt8 {
    // Public messages (unencrypted)
    case announce = 0x01        // "I'm here" with nickname
    case message = 0x02         // Public chat message  
    case leave = 0x03           // "I'm leaving"
    case requestSync = 0x21     // GCS filter-based sync request (local-only)
    
    // Noise encryption
    case noiseHandshake = 0x10  // Handshake (init or response determined by payload)
    case noiseEncrypted = 0x11  // All encrypted payloads (messages, receipts, etc.)
    
    // Fragmentation (simplified)
    case fragment = 0x20        // Single fragment type for large messages
    case fileTransfer = 0x22    // Binary file/audio/image payloads
}

public struct BitchatPacket {
    public let version: UInt8
    public let type: UInt8
    public let senderID: Data
    public let recipientID: Data?
    public let timestamp: UInt64
    public let payload: Data
    public var signature: Data?
    public var ttl: UInt8
    public var route: [Data]?
    public var isRSR: Bool
    
    public init(type: UInt8, senderID: Data, recipientID: Data?, timestamp: UInt64, payload: Data, signature: Data?, ttl: UInt8, version: UInt8 = 1, route: [Data]? = nil, isRSR: Bool = false) {
        self.version = version
        self.type = type
        self.senderID = senderID
        self.recipientID = recipientID
        self.timestamp = timestamp
        self.payload = payload
        self.signature = signature
        self.ttl = ttl
        self.route = route
        self.isRSR = isRSR
    }
    
    // Convenience initializer for new binary format
    public init(type: UInt8, ttl: UInt8, senderID: PeerID, payload: Data, isRSR: Bool = false) {
        self.version = 1
        self.type = type
        // Convert hex string peer ID to binary data (8 bytes)
        var senderData = Data()
        var tempID = senderID.id
        while tempID.count >= 2 {
            let hexByte = String(tempID.prefix(2))
            if let byte = UInt8(hexByte, radix: 16) {
                senderData.append(byte)
            }
            tempID = String(tempID.dropFirst(2))
        }
        self.senderID = senderData
        self.recipientID = nil
        self.timestamp = UInt64(Date().timeIntervalSince1970 * 1000)
        self.payload = payload
        self.signature = nil
        self.ttl = ttl
        self.route = nil
        self.isRSR = isRSR
    }

    // Métodos para encode/decode binario
    public func toBinaryData(padding: Bool) -> Data? {
        // Stub implementation - should encode packet to binary
        return nil
    }
    
    public func toBinaryDataForSigning() -> Data? {
        // Stub implementation - should encode packet for signing
        return nil
    }
}