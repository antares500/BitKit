// ChatManager.swift - Gestiona chats privados
import Foundation
import BitCore

public protocol ChatDelegate: AnyObject {
    func didReceivePrivateMessage(from peerID: PeerID, content: String)
}

public class ChatManager: ObservableObject {
    public weak var delegate: ChatDelegate?
    
    public init() {}
    
    public func sendPrivateMessage(to peerID: PeerID, content: String) {
        // Usar Transport para enviar
        // transport.sendPrivate(content, to: peerID)
    }
    
    public func receiveMessage(from peerID: PeerID, content: String) {
        delegate?.didReceivePrivateMessage(from: peerID, content: content)
    }
}