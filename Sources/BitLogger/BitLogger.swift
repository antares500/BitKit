import Foundation

/// Simple logger for BitKit
public enum BitLogger {
    public enum Category: String {
        case session, sync, security, error, info, general
    }
    
    public enum KeyOperation: String {
        case load, generate, delete
    }
    
    public static func log(_ message: String, category: Category = .general) {
        print("[\(category.rawValue)] \(message)")
    }
    
    public static func debug(_ message: String, category: Category = .general) {
        log(message, category: category)
    }
    
    public static func error(_ message: String, category: Category = .error) {
        log("❌ \(message)", category: .error)
    }
    
    public static func error(_ error: Error, context: String, category: Category = .error) {
        log("❌ \(context): \(error.localizedDescription)", category: category)
    }
    
    public static func warning(_ message: String, category: Category = .general) {
        log("⚠️ \(message)", category: category)
    }
    
    public static func info(_ message: String, category: Category = .info) {
        log(message, category: category)
    }
    
    public static func logKeyOperation(_ operation: KeyOperation, keyType: String, success: Bool) {
        let status = success ? "✅" : "❌"
        info("\(status) \(operation.rawValue) \(keyType) key", category: .security)
    }
}