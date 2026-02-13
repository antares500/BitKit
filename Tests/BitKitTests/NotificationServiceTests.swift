import XCTest
@testable import BitKit

final class NotificationServiceTests: XCTestCase {
    func testInitialization() {
        let service = NotificationService()
        XCTAssertNotNil(service)
    }

    func testScheduleAlertDoesNotCrash() {
        let service = NotificationService()
        service.scheduleAlert(for: "Test message", from: "peer1")
        XCTAssertTrue(true)
    }
}
