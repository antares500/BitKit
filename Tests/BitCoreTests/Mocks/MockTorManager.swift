// filepath: Tests/BitCoreTests/Mocks/MockTorManager.swift
import Foundation
@testable import BitTor

class MockTorManager: TorManager {
    var isReadyMock = true
    var isForegroundMock = true
    var torEnforcedMock = false
    
    override var isReady: Bool { isReadyMock }
    
    override func isForeground() -> Bool { isForegroundMock }
    
    override var torEnforced: Bool { torEnforcedMock }
    
    override func awaitReady(timeout: Double) async -> Bool { isReadyMock }
}