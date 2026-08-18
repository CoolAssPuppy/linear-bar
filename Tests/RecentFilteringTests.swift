import XCTest
@testable import LinearBar

final class RecentFilteringTests: XCTestCase {
    func testAllTimeIncludesItemsRegardlessOfUpdateDate() {
        let oldDate = Date(timeIntervalSince1970: 1)

        XCTAssertTrue(RecentView.TimeFilter.allTime.includes(updatedAt: oldDate, now: Date()))
        XCTAssertTrue(RecentView.TimeFilter.allTime.includes(updatedAt: nil, now: Date()))
    }

    func testLastSevenDaysExcludesOlderItemsAndMissingDates() {
        let now = Date(timeIntervalSince1970: 10_000_000)

        XCTAssertTrue(RecentView.TimeFilter.week.includes(
            updatedAt: now.addingTimeInterval(-6 * 24 * 60 * 60),
            now: now
        ))
        XCTAssertFalse(RecentView.TimeFilter.week.includes(
            updatedAt: now.addingTimeInterval(-8 * 24 * 60 * 60),
            now: now
        ))
        XCTAssertFalse(RecentView.TimeFilter.week.includes(updatedAt: nil, now: now))
    }

    func testLastThirtyDaysUsesCalendarDayWindow() {
        let now = Date(timeIntervalSince1970: 10_000_000)

        XCTAssertTrue(RecentView.TimeFilter.month.includes(
            updatedAt: now.addingTimeInterval(-29 * 24 * 60 * 60),
            now: now
        ))
        XCTAssertFalse(RecentView.TimeFilter.month.includes(
            updatedAt: now.addingTimeInterval(-31 * 24 * 60 * 60),
            now: now
        ))
    }

    func testTimeFilterLabelsDescribeTimeInsteadOfOwnership() {
        XCTAssertEqual(RecentView.TimeFilter.allTime.label, "All Time")
        XCTAssertEqual(RecentView.TimeFilter.week.label, "Last 7 days")
        XCTAssertEqual(RecentView.TimeFilter.month.label, "Last 30 days")
    }

    func testTypeFilterIncludesOnlyRequestedArtifactTypes() {
        XCTAssertTrue(RecentView.TypeFilter.all.includesIssues)
        XCTAssertTrue(RecentView.TypeFilter.all.includesProjects)
        XCTAssertTrue(RecentView.TypeFilter.all.includesInitiatives)
        XCTAssertTrue(RecentView.TypeFilter.issues.includesIssues)
        XCTAssertFalse(RecentView.TypeFilter.issues.includesProjects)
        XCTAssertFalse(RecentView.TypeFilter.issues.includesInitiatives)
    }
}
