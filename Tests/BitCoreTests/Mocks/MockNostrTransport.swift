// filepath: Tests/BitCoreTests/Mocks/MockNostrTransport.swift
import Foundation
@testable import BitTransport

class MockNostrTransport: NostrTransport {
    var sendEventCalled = false
    
    override func sendMessage(_ content: String, mentions: [String]) {
        sendEventCalled = true
    }
}