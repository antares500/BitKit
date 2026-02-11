// ReliabilityManager.swift - Asegura la entrega de mensajes
import Foundation
import BitCore

public class ReliabilityManager: ObservableObject {
    private var pendingMessages: [String: BitMessage] = [:]
    
    public init() {}
    
    public func sendReliableMessage(_ message: BitMessage, to peerID: PeerID) {
        let id = UUID().uuidString
        pendingMessages[id] = message
        // Enviar con ACK
        // transport.send(message, to: peerID, withReliability: true)
    }
    
    public func acknowledgeMessage(_ messageID: String) {
        pendingMessages.removeValue(forKey: messageID)
    }
    
    public func retryPendingMessages() {
        // Reintentar mensajes pendientes
    }
}