import Foundation
import Combine

public protocol ModerationDelegate: AnyObject {
    func userBanned(userId: String, reason: String?)
    func userUnbanned(userId: String)
    func messageBlocked(messageId: String, reason: String?)
}

public class ModerationManager {
    public weak var delegate: ModerationDelegate?

    private var bannedUsers: Set<String> = []
    private var blockedMessages: Set<String> = []
    private let persistenceKey = "moderationData"

    public init() {
        loadModerationData()
    }

    // Ban a user
    public func banUser(userId: String, reason: String? = nil) {
        bannedUsers.insert(userId)
        saveModerationData()
        delegate?.userBanned(userId: userId, reason: reason)
    }

    // Unban a user
    public func unbanUser(userId: String) {
        bannedUsers.remove(userId)
        saveModerationData()
        delegate?.userUnbanned(userId: userId)
    }

    // Check if user is banned
    public func isUserBanned(userId: String) -> Bool {
        return bannedUsers.contains(userId)
    }

    // Block a message
    public func blockMessage(messageId: String, reason: String? = nil) {
        blockedMessages.insert(messageId)
        saveModerationData()
        delegate?.messageBlocked(messageId: messageId, reason: reason)
    }

    // Check if message is blocked
    public func isMessageBlocked(messageId: String) -> Bool {
        return blockedMessages.contains(messageId)
    }

    // Get list of banned users
    public func getBannedUsers() -> [String] {
        return Array(bannedUsers)
    }

    // Clear all bans (admin only)
    public func clearAllBans() {
        bannedUsers.removeAll()
        saveModerationData()
    }

    private func saveModerationData() {
        let data = ModerationData(bannedUsers: bannedUsers, blockedMessages: blockedMessages)
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: persistenceKey)
        }
    }

    private func loadModerationData() {
        if let data = UserDefaults.standard.data(forKey: persistenceKey),
           let decoded = try? JSONDecoder().decode(ModerationData.self, from: data) {
            bannedUsers = decoded.bannedUsers
            blockedMessages = decoded.blockedMessages
        }
    }
}

private struct ModerationData: Codable {
    let bannedUsers: Set<String>
    let blockedMessages: Set<String>
}