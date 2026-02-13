import Foundation

public struct Group {
    public let id: UUID
    public var members: [String]  // Peer IDs
    public var moderators: [String]
    public var isPublic: Bool
    public var name: String
}

public class GroupManager {
    private var groups: [UUID: Group] = [:]
    
    public func createGroup(name: String, isPublic: Bool, creator: String) -> Group {
        let group = Group(id: UUID(), members: [creator], moderators: [creator], isPublic: isPublic, name: name)
        groups[group.id] = group
        return group
    }
    
    public func joinGroup(_ groupID: UUID, peer: String) {
        guard var group = groups[groupID] else { return }
        group.members.append(peer)
        groups[groupID] = group
    }
    
    public func moderateGroup(_ groupID: UUID, action: ModerationAction, by moderator: String) {
        guard var group = groups[groupID], group.moderators.contains(moderator) else { return }
        switch action {
        case .ban(let peer):
            group.members.removeAll { $0 == peer }
        case .mute(let peer, let duration):
            // Silenciar mensajes de peer por duration segundos
            // Implementación simple: marcar como muted hasta timestamp
            let muteUntil = Date().addingTimeInterval(duration)
            // Aquí podrías añadir un diccionario de mutes: [peer: Date]
            // Por simplicidad, solo log
            print("Peer \(peer) muted until \(muteUntil)")
        }
        groups[groupID] = group
    }
    
    public enum ModerationAction {
        case ban(peer: String)
        case mute(peer: String, duration: TimeInterval)
    }
}