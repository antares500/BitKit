// filepath: Tests/BitCoreTests/Mocks/MockBLETransport.swift
import Foundation
@testable import BitTransport

class MockBLETransport: BLETransport {
    var isReachableMock = true
    
    override func isPeerReachable(_ peerID: PeerID) -> Bool { isReachableMock }
}