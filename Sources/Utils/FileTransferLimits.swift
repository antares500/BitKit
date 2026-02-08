// FileTransferLimits.swift
import Foundation

public enum FileTransferLimits {
    public static func isValidPayload(_ size: Int) -> Bool {
        // Stub implementation
        return size < 1024 * 1024 // 1MB limit
    }
}