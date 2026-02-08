// RequestSyncManager.swift - De REQUEST_SYNC_MANAGER.md
import Foundation

public class RequestSyncManager {
    private var pendingRequests: [PeerID: Date] = [:]
    private let timeout: TimeInterval = 30 // 30 seconds

    public init() {}

    public func registerRequest(to peerID: PeerID) {
        pendingRequests[peerID] = Date()
    }

    public func isValidResponse(from peerID: PeerID, isRSR: Bool) -> Bool {
        guard isRSR, let requestTime = pendingRequests[peerID] else { return false }
        let now = Date()
        if now.timeIntervalSince(requestTime) > timeout {
            pendingRequests.removeValue(forKey: peerID)
            return false
        }
        return true
    }

    public func cleanupExpiredRequests() {
        let now = Date()
        pendingRequests = pendingRequests.filter { now.timeIntervalSince($0.value) <= timeout }
    }

    /// Periodic cleanup of expired requests
    public func cleanup() {
        pendingRequests = pendingRequests.filter { _, timestamp in
            Date().timeIntervalSince(timestamp) <= timeout
        }
    }
}