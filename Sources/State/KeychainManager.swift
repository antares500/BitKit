import Foundation
import BitCore

public class KeychainManager: KeychainManagerProtocol {
    // Stub implementation for the package
    // In a real app, this would use iOS/macOS Keychain
    
    private var storage: [String: Data] = [:]
    
    public init() {}
    
    public func getIdentityKey(forKey key: String) -> Data? {
        return storage[key]
    }
    
    public func saveIdentityKey(_ data: Data, forKey key: String) -> Bool {
        storage[key] = data
        return true
    }
    
    public func deleteIdentityKey(forKey key: String) -> Bool {
        storage.removeValue(forKey: key)
        return true
    }
    
    public func save(key: String, data: Data, service: String, accessible: CFString?) {
        let fullKey = "\(service).\(key)"
        storage[fullKey] = data
    }
    
    public func load(key: String, service: String) -> Data? {
        let fullKey = "\(service).\(key)"
        return storage[fullKey]
    }
    
    public func delete(key: String, service: String) {
        let fullKey = "\(service).\(key)"
        storage.removeValue(forKey: fullKey)
    }
}