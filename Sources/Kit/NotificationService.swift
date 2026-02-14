import Foundation
import UserNotifications

public final class NotificationService {
    // Avoid calling UNUserNotificationCenter.current() during unit tests where
    // the main bundle may not be available and calling `current()` can crash.
    private var center: UNUserNotificationCenter? = {
        if NSClassFromString("XCTestCase") != nil { return nil }
        return UNUserNotificationCenter.current()
    }()

    public init() {}

    public func requestAuthorization() {
        center?.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    public func scheduleAlert(for message: String, from peer: String) {
        guard let center = center else { return }

        let content = UNMutableNotificationContent()
        content.title = "Nuevo mensaje de \(peer)"
        content.body = message
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        center.add(request) { _ in }
    }
}
