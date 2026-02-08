// MimeType.swift
import Foundation

public enum MimeType {
    case image
    case audio
    case video
    case other
    
    public init?(_ string: String) {
        // Stub implementation
        self = .other
    }
    
    public var isAllowed: Bool {
        // Stub implementation
        return true
    }
}