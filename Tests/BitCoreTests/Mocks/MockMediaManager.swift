// filepath: Tests/BitCoreTests/Mocks/MockMediaManager.swift
import Foundation
@testable import BitMedia

// Minimal mock for MediaManager API used in tests
class MockMediaManager {
    var compressCalled = false

    func compress(data: Data) -> Data {
        compressCalled = true
        return data
    }
}