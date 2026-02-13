import Foundation
import UserNotifications

public final class NotificationService {
    private let center = UNUserNotificationCenter.current()

    public init() {}

    public func requestAuthorization() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    public func scheduleAlert(for message: String, from peer: String) {
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
