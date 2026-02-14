// filepath: Tests/BitCoreTests/Mocks/MockTorManager.swift
import Foundation

// Simple mock that mirrors the minimal TorManager API used in tests
class MockTorManager {
    var isReadyMock = true
    var isForegroundMock = true
    var torEnforcedMock = false

    var isReady: Bool { isReadyMock }

    func isForeground() -> Bool { isForegroundMock }

    var torEnforced: Bool { torEnforcedMock }

    func awaitReady(timeout: Double = 25.0) async -> Bool { isReadyMock }
}