import XCTest
@testable import LinearBar

final class InboxCountTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    func testCountsUnreadOpenNotifications() {
        let items = [
            notification(id: "1", readAt: nil),
            notification(id: "2", readAt: now),
            notification(id: "3", readAt: nil)
        ]

        XCTAssertEqual(InboxCount.unread(in: items, now: now), 2)
    }

    func testIgnoresArchivedAndSnoozed() {
        let items = [
            notification(id: "1", archivedAt: now),
            notification(id: "2", snoozedUntilAt: now.addingTimeInterval(60)),
            notification(id: "3", snoozedUntilAt: now.addingTimeInterval(-60))
        ]

        XCTAssertEqual(InboxCount.unread(in: items, now: now), 1)
        XCTAssertEqual(InboxCount.inboxItems(in: items, now: now).map(\.id), ["3"])
    }

    func testCountsOneRowPerGroupingKey() {
        let items = [
            notification(id: "old", groupingKey: "issue-1", groupingPriority: 1, createdAt: now.addingTimeInterval(-20)),
            notification(id: "new", groupingKey: "issue-1", groupingPriority: 2, createdAt: now.addingTimeInterval(-5)),
            notification(id: "other", groupingKey: "issue-2", createdAt: now)
        ]

        XCTAssertEqual(InboxCount.unread(in: items, now: now), 2)
        XCTAssertEqual(InboxCount.inboxItems(in: items, now: now).map(\.id), ["other", "new"])
    }

    func testBadgeUsesCurrentWorkspace() {
        let perAccount = ["a@x.com": 3, "b@x.com": 7]

        XCTAssertEqual(InboxCount.badge(total: 10, perAccount: perAccount, currentEmail: "a@x.com"), 3)
        XCTAssertEqual(InboxCount.badge(total: 10, perAccount: perAccount, currentEmail: nil), 10)
    }

    private func notification(
        id: String,
        readAt: Date? = nil,
        archivedAt: Date? = nil,
        snoozedUntilAt: Date? = nil,
        groupingKey: String? = nil,
        groupingPriority: Double? = nil,
        createdAt: Date? = nil
    ) -> LinearNotification {
        LinearNotification(
            id: id,
            type: "issueMention",
            createdAt: createdAt ?? now,
            readAt: readAt,
            archivedAt: archivedAt,
            snoozedUntilAt: snoozedUntilAt,
            actor: nil,
            issue: nil,
            project: nil,
            document: nil,
            groupingKey: groupingKey,
            groupingPriority: groupingPriority
        )
    }
}
