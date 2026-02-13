import XCTest
@testable import BitCore

final class MessageRouterTests: XCTestCase {
    func testInitWithEmptyTransports() {
        let router = MessageRouter(transports: [])
        XCTAssertNotNil(router)
    }

    func testSendMessageDoesNotCrash() {
        let router = MessageRouter(transports: [])
        router.sendMessage("Hello", mentions: [])
        XCTAssertTrue(true)
    }

    func testSearchAndFilterCompilePath() {
        let router = MessageRouter(transports: [])
        let found = router.searchMessages(containing: "hello")
        let filtered = router.filterMessages(by: "peer1")
        XCTAssertNotNil(found)
        XCTAssertNotNil(filtered)
    }
}
