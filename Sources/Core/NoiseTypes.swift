/// Types of payloads embedded within noiseEncrypted messages.
/// The first byte of decrypted Noise payload indicates the type.
/// This provides privacy - observers can't distinguish message types.
public enum NoisePayloadType: UInt8 {
    // Messages and status
    case privateMessage = 0x01      // Private chat message
    case readReceipt = 0x02         // Message was read
    case delivered = 0x03           // Message was delivered
    // Verification (QR-based OOB binding)
    case verifyChallenge = 0x10     // Verification challenge
    case verifyResponse  = 0x11     // Verification response
    
    var description: String {
        switch self {
        case .privateMessage: return "privateMessage"
        case .readReceipt: return "readReceipt"
        case .delivered: return "delivered"
        case .verifyChallenge: return "verifyChallenge"
        case .verifyResponse: return "verifyResponse"
        }
    }
}

// Lazy handshake state tracking
public enum LazyHandshakeState {
    case none                    // No session, no handshake attempted
    case handshakeQueued        // User action requires handshake
    case handshaking           // Currently in handshake process
    case established           // Session ready for use
    case failed(Error)         // Handshake failed
}