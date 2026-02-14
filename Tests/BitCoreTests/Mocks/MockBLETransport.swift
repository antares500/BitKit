// filepath: Tests/BitCoreTests/Mocks/MockBLETransport.swift
import Foundation
@testable import BitTransport
@testable import BitCore

// Minimal mock that provides the small API used by tests (Transport implementations removed/renamed)
class MockBLETransport {
    var isReachableMock = true

    func isPeerReachable(_ peerID: PeerID) -> Bool { isReachableMock }
}