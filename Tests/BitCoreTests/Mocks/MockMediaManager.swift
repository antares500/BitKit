// filepath: Tests/BitCoreTests/Mocks/MockMediaManager.swift
import Foundation
@testable import BitMedia

class MockMediaManager: MediaManager {
    var compressCalled = false
    
    override func compress(data: Data) -> Data {
        compressCalled = true
        return data
    }
}