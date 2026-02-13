import XCTest
@testable import BitKit

final class AnalyticsServiceTests: XCTestCase {
    func testTrackEventWhenEnabled() {
        let analytics = AnalyticsService()
        analytics.isEnabled = true
        analytics.trackEvent("messageSent")
        XCTAssertEqual(analytics.getMetrics()["messageSent"], 1)
    }

    func testTrackEventWhenDisabled() {
        let analytics = AnalyticsService()
        analytics.isEnabled = false
        analytics.trackEvent("messageSent")
        XCTAssertTrue(analytics.getMetrics().isEmpty)
    }
}
