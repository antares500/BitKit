//
// NostrFilter.swift
// bitchat
//
// This is free and unencumbered software released into the public domain.
// For more information, see <https://unlicense.org>
//

import Foundation

/// Nostr filter structure
public struct NostrFilter: Codable {
    public var ids: [String]?
    public var authors: [String]?
    public var kinds: [Int]?
    public var since: Int?
    public var until: Int?
    public var limit: Int?
    
    // Tag filters - stored internally but encoded specially
    public var tagFilters: [String: [String]]?

    public init(ids: [String]? = nil, authors: [String]? = nil, kinds: [Int]? = nil, since: Int? = nil, until: Int? = nil, limit: Int? = nil, tagFilters: [String: [String]]? = nil) {
        self.ids = ids
        self.authors = authors
        self.kinds = kinds
        self.since = since
        self.until = until
        self.limit = limit
        self.tagFilters = tagFilters
    }
    
    // Custom encoding to handle tag filters
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(ids, forKey: .ids)
        try container.encodeIfPresent(authors, forKey: .authors)
        try container.encodeIfPresent(kinds, forKey: .kinds)
        try container.encodeIfPresent(since, forKey: .since)
        try container.encodeIfPresent(until, forKey: .until)
        try container.encodeIfPresent(limit, forKey: .limit)
        
        // Encode tag filters with # prefix
        if let tagFilters = tagFilters {
            for (tag, values) in tagFilters {
                try container.encode(values, forKey: CodingKeys(stringValue: "#\(tag)")!)
            }
        }
    }
}