import XCTest
@testable import BitCore

final class GroupManagerTests: XCTestCase {
    func testCreateGroup() {
        let manager = GroupManager()
        let group = manager.createGroup(name: "Test Group", isPublic: true, creator: "creator1")
        XCTAssertEqual(group.name, "Test Group")
        XCTAssertTrue(group.isPublic)
        XCTAssertEqual(group.members, ["creator1"])
    }

    func testModerateGroupBanCompiles() {
        let manager = GroupManager()
        let group = manager.createGroup(name: "Test", isPublic: true, creator: "creator1")
        manager.joinGroup(group.id, peer: "badPeer")
        manager.moderateGroup(group.id, action: GroupManager.ModerationAction.ban(peer: "badPeer"), by: "creator1")
        XCTAssertTrue(true)
    }
}
