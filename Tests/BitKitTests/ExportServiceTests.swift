import XCTest
@testable import BitKit
@testable import BitCore

final class ExportServiceTests: XCTestCase {
    func testServiceInitialization() {
        let service = ExportService()
        XCTAssertNotNil(service)
    }

    func testExportImportEmptyConversation() throws {
        let service = ExportService()
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("bitkit-export-test.json")

        try service.exportConversation(messages: [], to: url)
        let imported = try service.importConversation(from: url)

        XCTAssertTrue(imported.isEmpty)
    }
}
