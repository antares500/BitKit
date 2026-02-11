//
// BitFilePacket.swift
// bitchat
//
// This is free and unencumbered software released into the public domain.
// For more information, see <https://unlicense.org>
//

import Foundation

/// File packet structure
public struct BitFilePacket {
    public let data: Data
    public let filename: String
    public let mimeType: String

    public func encode() -> Data? {
        // Stub implementation
        return nil
    }
    
    public static func decode(_ data: Data) -> BitFilePacket? {
        // Stub implementation
        return nil
    }
}