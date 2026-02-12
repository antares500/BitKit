// VerificationManager.swift - Verifica identidades y mensajes
import Foundation
import BitCore

import BitState

public class VerificationManager: ObservableObject {
    private let identityManager: BitState.SecureIdentityStateManagerProtocol
    
    public init(identityManager: BitState.SecureIdentityStateManagerProtocol) {
        self.identityManager = identityManager
    }
    
    public func verifyIdentity(_ peerID: PeerID) -> Bool {
        // Verificar si el peerID tiene una identidad criptográfica válida
        let identities = identityManager.getCryptoIdentitiesByPeerIDPrefix(peerID)
        return !identities.isEmpty
    }
    
    public func verifyMessage(_ message: BitMessage) -> Bool {
        // Verificar integridad básica del mensaje
        return !message.content.isEmpty && message.senderPeerID != nil
    }
}