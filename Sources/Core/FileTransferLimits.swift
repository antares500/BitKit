// FileTransferLimits.swift
import Foundation

public enum FileTransferLimits {
    public static let maxPayloadBytes = 1024 * 1024 // 1MB
    public static let maxFramedFileBytes = 2 * 1024 * 1024 // 2MB
    
    public static func isValidPayload(_ size: Int) -> Bool {
        // Stub - check if payload size is valid
        return size <= maxPayloadBytes
    }
}