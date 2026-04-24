import XCTest
@testable import LinearBar

@MainActor
final class LinearAPIRetryAfterTests: XCTestCase {

    func testRetryAfterParsesIntegerSecondsAndCapsTo15() throws {
        let response = try makeResponse(headers: ["Retry-After": "120"])
        XCTAssertEqual(LinearAPI.retryAfterDelay(from: response), 15)
    }

    func testRetryAfterParsesHttpDate() throws {
        let target = Date().addingTimeInterval(10)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "EEE',' dd MMM yyyy HH':'mm':'ss z"

        let response = try makeResponse(headers: ["Retry-After": formatter.string(from: target)])
        let delay = LinearAPI.retryAfterDelay(from: response)
        XCTAssertNotNil(delay)
        XCTAssertGreaterThanOrEqual(delay ?? 0, 0)
        XCTAssertLessThanOrEqual(delay ?? 0, 15)
    }

    func testRetryAfterReturnsNilWhenMissingOrInvalid() throws {
        let missing = try makeResponse(headers: [:])
        XCTAssertNil(LinearAPI.retryAfterDelay(from: missing))

        let invalid = try makeResponse(headers: ["Retry-After": "nonsense"])
        XCTAssertNil(LinearAPI.retryAfterDelay(from: invalid))
    }

    private func makeResponse(headers: [String: String]) throws -> HTTPURLResponse {
        guard let response = HTTPURLResponse(
            url: SafeExternalURL.mustParse("https://api.linear.app/graphql"),
            statusCode: 429,
            httpVersion: nil,
            headerFields: headers
        ) else {
            throw XCTSkip("Could not construct HTTPURLResponse")
        }
        return response
    }
}
