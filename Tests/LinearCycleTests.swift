import XCTest
@testable import LinearBar

final class LinearCycleTests: XCTestCase {

    // MARK: - pace classifier

    func testPaceReportsDoneWhenProgressIsEffectivelyComplete() {
        let cycle = makeCycle(progress: 0.999, startOffsetDays: -10, endOffsetDays: 0)
        XCTAssertEqual(cycle.pace, .done)
    }

    func testPaceReportsStartingBeforeStartDate() {
        let cycle = makeCycle(progress: 0, startOffsetDays: 1, endOffsetDays: 14)
        XCTAssertEqual(cycle.pace, .starting)
    }

    func testPaceReportsBehindWhenProgressTrailsElapsed() {
        // 10 days into a 14-day cycle (~71% elapsed) with only 40% done.
        let cycle = makeCycle(progress: 0.4, startOffsetDays: -10, endOffsetDays: 4)
        XCTAssertEqual(cycle.pace, .behind)
    }

    func testPaceReportsOnTrackWhenProgressMatchesElapsed() {
        // 7 days into a 14-day cycle (~50% elapsed) with 55% done.
        let cycle = makeCycle(progress: 0.55, startOffsetDays: -7, endOffsetDays: 7)
        XCTAssertEqual(cycle.pace, .onTrack)
    }

    // MARK: - daysLeft

    func testDaysLeftClampsToZeroForEndedCycles() {
        let cycle = makeCycle(progress: 1, startOffsetDays: -20, endOffsetDays: -5)
        XCTAssertEqual(cycle.daysLeft, 0)
    }

    func testDaysLeftForActiveCycle() {
        // Calendar.dateComponents rounds to the nearest whole day; a 10-day
        // offset can land on either 9 or 10 depending on time of day. Guard
        // against day-boundary flakiness with a tight range.
        let cycle = makeCycle(progress: 0.5, startOffsetDays: -4, endOffsetDays: 10)
        XCTAssertTrue((9...10).contains(cycle.daysLeft), "daysLeft = \(cycle.daysLeft)")
    }

    // MARK: - scopeDeltaFraction

    func testScopeDeltaFractionPositiveOnGrowth() {
        let cycle = makeCycle(
            progress: 0.5,
            startOffsetDays: -4,
            endOffsetDays: 3,
            scopeHistory: [40, 42, 45, 50]
        )
        XCTAssertEqual(cycle.scopeDeltaFraction ?? 0, 0.25, accuracy: 0.0001)
    }

    func testScopeDeltaFractionNilWithoutHistory() {
        let cycle = makeCycle(progress: 0, startOffsetDays: 1, endOffsetDays: 14, scopeHistory: [])
        XCTAssertNil(cycle.scopeDeltaFraction)
    }

    /// When scope starts at 0 (shouldn't happen in practice — Linear seeds
    /// the array at cycle creation) the delta would divide by zero. Verify
    /// we return nil instead of NaN/inf.
    func testScopeDeltaFractionNilWhenInitialScopeZero() {
        let cycle = makeCycle(
            progress: 0.5,
            startOffsetDays: -4,
            endOffsetDays: 3,
            scopeHistory: [0, 20, 40]
        )
        XCTAssertNil(cycle.scopeDeltaFraction)
    }

    // MARK: - helpers

    private func makeCycle(
        progress: Double,
        startOffsetDays: Int,
        endOffsetDays: Int,
        scopeHistory: [Double] = [40, 45, 50],
        completedScopeHistory: [Double] = [0, 20, 30],
        inProgressScopeHistory: [Double] = [0, 5, 5]
    ) -> LinearCycle {
        let calendar = Calendar.current
        let now = Date()
        return LinearCycle(
            id: "cycle",
            name: nil,
            number: 1,
            startsAt: calendar.date(byAdding: .day, value: startOffsetDays, to: now) ?? now,
            endsAt: calendar.date(byAdding: .day, value: endOffsetDays, to: now) ?? now,
            progress: progress,
            scopeHistory: scopeHistory,
            completedScopeHistory: completedScopeHistory,
            inProgressScopeHistory: inProgressScopeHistory,
            issues: LinearCycle.IssueCollection(nodes: [])
        )
    }
}
