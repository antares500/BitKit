import Foundation
import CryptoKit
import BitCore

public enum CryptoUtils {
    public static func generateFingerprint() throws -> String {
        let randomData = Data((0..<32).map { _ in UInt8.random(in: 0...255) })
        return randomData.hexEncodedString()
    }
}