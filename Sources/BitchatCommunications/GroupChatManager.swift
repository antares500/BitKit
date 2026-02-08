// GroupChatManager.swift - Gestiona chats grupales
import Foundation
import BitchatCore

public protocol GroupChatDelegate: AnyObject {
    func didJoinGroup(_ groupID: String)
    func didLeaveGroup(_ groupID: String)
    func didReceiveGroupMessage(from groupID: String, peerID: PeerID, content: String)
}

public class GroupChatManager {
    public weak var delegate: GroupChatDelegate?
    private var groups: [String: [PeerID]] = [:]  // groupID: members
    
    public func createGroup(name: String, members: [PeerID]) -> String {
        let groupID = UUID().uuidString
        groups[groupID] = members
        delegate?.didJoinGroup(groupID)
        return groupID
    }
    
    public func joinGroup(_ groupID: String) {
        // Simula join
        delegate?.didJoinGroup(groupID)
    }
    
    public func sendGroupMessage(to groupID: String, content: String) {
        guard let members = groups[groupID] else { return }
        // Envía a cada miembro (usa Transport)
        for _ in members {
            // transport.sendPrivate(content, to: member, ...)
        }
    }
}