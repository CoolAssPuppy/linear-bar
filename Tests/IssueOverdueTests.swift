import XCTest
@testable import LinearBar

/// `isOverdue` drives the trailing "Due …" chip color on the Mine tab. The
/// underlying DateParsing helper is shared across Issue, Project, and
/// Initiative — verifying it once here guards all three.
final class IssueOverdueTests: XCTestCase {

    func testFutureDueDateIsNotOverdue() {
        let issue = makeIssue(dueDate: isoDate(daysFromNow: 7))
        XCTAssertFalse(issue.isOverdue)
    }

    func testPastDueDateIsOverdue() {
        let issue = makeIssue(dueDate: isoDate(daysFromNow: -1))
        XCTAssertTrue(issue.isOverdue)
    }

    func testNilDueDateIsNotOverdue() {
        XCTAssertFalse(makeIssue(dueDate: nil).isOverdue)
    }

    func testMalformedDueDateIsNotOverdue() {
        XCTAssertFalse(makeIssue(dueDate: "not-a-date").isOverdue)
    }

    // MARK: - Helpers

    private func isoDate(daysFromNow: Int) -> String {
        let date = Calendar.current.date(byAdding: .day, value: daysFromNow, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.string(from: date)
    }

    private func makeIssue(dueDate: String?) -> Issue {
        Issue(
            id: "id",
            identifier: "TEST-1",
            title: "Test",
            description: nil,
            url: "https://linear.app/test/issue/TEST-1",
            createdAt: Date(),
            updatedAt: Date(),
            dueDate: dueDate,
            state: IssueState(name: "Todo", type: "unstarted"),
            priority: 3,
            priorityLabel: "Medium",
            assignee: nil,
            team: nil,
            labels: nil,
            project: nil,
            parent: nil
        )
    }
}
