import XCTest
@testable import LinearBar

/// Covers every bucket in `RelativeTimeFormatter.shortLabel`. Uses a fixed
/// reference date so "now" is deterministic across machines.
final class RelativeTimeFormatterTests: XCTestCase {
    private let reference = Date(timeIntervalSince1970: 1_800_000_000)

    func testSecondsBucket() {
        let date = reference.addingTimeInterval(-30)
        XCTAssertEqual(RelativeTimeFormatter.shortLabel(for: date, reference: reference), "30s")
    }

    func testNowForZeroOrFutureReference() {
        XCTAssertEqual(RelativeTimeFormatter.shortLabel(for: reference, reference: reference), "now")
        let future = reference.addingTimeInterval(120)
        XCTAssertEqual(RelativeTimeFormatter.shortLabel(for: future, reference: reference), "now")
    }

    func testMinutesBucket() {
        let date = reference.addingTimeInterval(-7 * 60)
        XCTAssertEqual(RelativeTimeFormatter.shortLabel(for: date, reference: reference), "7m")
    }

    func testHoursBucket() {
        let date = reference.addingTimeInterval(-3 * 3600)
        XCTAssertEqual(RelativeTimeFormatter.shortLabel(for: date, reference: reference), "3h")
    }

    func testDaysBucket() {
        let date = reference.addingTimeInterval(-4 * 86_400)
        XCTAssertEqual(RelativeTimeFormatter.shortLabel(for: date, reference: reference), "4d")
    }

    func testWeeksBucket() {
        let date = reference.addingTimeInterval(-14 * 86_400)
        XCTAssertEqual(RelativeTimeFormatter.shortLabel(for: date, reference: reference), "2w")
    }

    func testMonthsBucket() {
        let date = reference.addingTimeInterval(-60 * 86_400)
        XCTAssertEqual(RelativeTimeFormatter.shortLabel(for: date, reference: reference), "2mo")
    }

    func testYearsBucket() {
        let date = reference.addingTimeInterval(-400 * 86_400)
        XCTAssertEqual(RelativeTimeFormatter.shortLabel(for: date, reference: reference), "1y")
    }

    /// Bucket boundaries: 59s still lives in the seconds range; 60s flips
    /// to minutes. Guards against off-by-one slip in the threshold checks.
    func testBoundaryTransitions() {
        XCTAssertEqual(RelativeTimeFormatter.shortLabel(for: reference.addingTimeInterval(-59), reference: reference), "59s")
        XCTAssertEqual(RelativeTimeFormatter.shortLabel(for: reference.addingTimeInterval(-60), reference: reference), "1m")
        XCTAssertEqual(RelativeTimeFormatter.shortLabel(for: reference.addingTimeInterval(-3599), reference: reference), "59m")
        XCTAssertEqual(RelativeTimeFormatter.shortLabel(for: reference.addingTimeInterval(-3600), reference: reference), "1h")
    }
}
