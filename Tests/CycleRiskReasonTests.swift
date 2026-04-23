import XCTest
@testable import LinearBar

/// Covers CycleIssue.riskReason so the Pulse at-risk ranking stays
/// deterministic. Severity order matters: SLA must always win.
final class CycleRiskReasonTests: XCTestCase {

    func testSLAWarningWhenBreachUpcoming() {
        let issue = makeCycleIssue(
            slaBreachesIn: .minutes(30),
            state: IssueState(name: "In Progress", type: "started"),
            assignee: User(name: "Maya"),
            updatedMinutesAgo: 60
        )

        guard case .slaWarning(let minutes) = issue.riskReason else {
            XCTFail("Expected slaWarning, got \(issue.riskReason)"); return
        }
        XCTAssertEqual(minutes, 30, accuracy: 1)
    }

    func testSLABreachedRendersMinutesLessThanOrEqualZero() {
        let issue = makeCycleIssue(
            slaBreachesIn: .minutes(-5),
            state: IssueState(name: "In Progress", type: "started"),
            assignee: User(name: "Maya"),
            updatedMinutesAgo: 60
        )

        XCTAssertEqual(issue.riskReason.label, "SLA breached")
    }

    func testStaleClassifiesStartedIssuesIdleOverThreeDays() {
        let issue = makeCycleIssue(
            slaBreachesIn: nil,
            state: IssueState(name: "In Progress", type: "started"),
            assignee: User(name: "Maya"),
            updatedDaysAgo: 5
        )

        guard case .stale(let days) = issue.riskReason else {
            XCTFail("Expected stale, got \(issue.riskReason)"); return
        }
        XCTAssertEqual(days, 5)
    }

    func testInProgressWhenStartedButNotStale() {
        let issue = makeCycleIssue(
            slaBreachesIn: nil,
            state: IssueState(name: "In Progress", type: "started"),
            assignee: User(name: "Maya"),
            updatedMinutesAgo: 30
        )
        XCTAssertEqual(issue.riskReason.label, "In progress")
    }

    func testUnassignedWhenNoAssigneeAndNotStarted() {
        let issue = makeCycleIssue(
            slaBreachesIn: nil,
            state: IssueState(name: "Todo", type: "unstarted"),
            assignee: nil,
            updatedMinutesAgo: 30
        )
        XCTAssertEqual(issue.riskReason.label, "Unassigned")
    }

    func testPendingWhenEverythingQuiet() {
        let issue = makeCycleIssue(
            slaBreachesIn: nil,
            state: IssueState(name: "Todo", type: "unstarted"),
            assignee: User(name: "Maya"),
            updatedMinutesAgo: 10
        )
        XCTAssertEqual(issue.riskReason.label, "Pending")
    }

    func testSeverityOrderingPutsSLAFirst() {
        let severities: [CycleRiskReason] = [
            .slaWarning(minutesLeft: 30),
            .stale(days: 5),
            .unassigned,
            .inProgress,
            .pending
        ]
        let order = severities.map { $0.severity }
        XCTAssertEqual(order, order.sorted())
    }

    func testCriticalMarksSLAAndStaleOnly() {
        XCTAssertTrue(CycleRiskReason.slaWarning(minutesLeft: 30).isCritical)
        XCTAssertTrue(CycleRiskReason.stale(days: 5).isCritical)
        XCTAssertFalse(CycleRiskReason.unassigned.isCritical)
        XCTAssertFalse(CycleRiskReason.inProgress.isCritical)
        XCTAssertFalse(CycleRiskReason.pending.isCritical)
    }

    // MARK: - Helpers

    private enum SLAOffset {
        case minutes(Int)

        var date: Date {
            switch self {
            case .minutes(let m):
                return Calendar.current.date(byAdding: .minute, value: m, to: Date()) ?? Date()
            }
        }
    }

    private func makeCycleIssue(
        slaBreachesIn: SLAOffset?,
        state: IssueState?,
        assignee: User?,
        updatedMinutesAgo: Int = 0,
        updatedDaysAgo: Int? = nil
    ) -> CycleIssue {
        let now = Date()
        let updatedAt: Date?
        if let days = updatedDaysAgo {
            updatedAt = Calendar.current.date(byAdding: .day, value: -days, to: now)
        } else {
            updatedAt = Calendar.current.date(byAdding: .minute, value: -updatedMinutesAgo, to: now)
        }

        return CycleIssue(
            id: "issue",
            identifier: "TEST-1",
            title: "Test issue",
            url: "https://linear.app/test/issue/TEST-1",
            updatedAt: updatedAt,
            dueDate: nil,
            priority: 2,
            priorityLabel: "High",
            state: state,
            assignee: assignee,
            slaBreachesAt: slaBreachesIn?.date
        )
    }
}
