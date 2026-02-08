// MessageDeduplicator.swift - Bloom dedup
import Foundation

public class MessageDeduplicator {
    // Bloom filter para deduplicar mensajes
    private var bloomFilter: [Bool] = Array(repeating: false, count: 1000) // Stub size

    public init() {}

    public func hasSeen(_ messageID: String) -> Bool {
        let hash = messageID.hashValue % bloomFilter.count
        return bloomFilter[hash]
    }

    public func markProcessed(_ id: String) {
        let hash = id.hashValue % bloomFilter.count
        bloomFilter[hash] = true
    }

    public func isDuplicate(_ messageID: String) -> Bool {
        return hasSeen(messageID)
    }

    public func contains(_ id: String) -> Bool {
        return hasSeen(id)
    }

    public func cleanup() {
        // Stub - cleanup old entries
    }

    public func reset() {
        bloomFilter = Array(repeating: false, count: bloomFilter.count)
    }
}