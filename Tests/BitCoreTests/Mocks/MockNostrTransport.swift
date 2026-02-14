// filepath: Tests/BitCoreTests/Mocks/MockNostrTransport.swift
import Foundation
@testable import BitTransport

// Minimal mock for tests — NostrTransport implementation moved/renamed in production code
class MockNostrTransport {
    var sendEventCalled = false

    func sendMessage(_ content: String, mentions: [String]) {
        sendEventCalled = true
    }
}