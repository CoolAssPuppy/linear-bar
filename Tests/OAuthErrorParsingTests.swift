import XCTest
@testable import LinearBar

@MainActor
final class OAuthErrorParsingTests: XCTestCase {

    func testParseOAuthErrorPrefersErrorDescription() throws {
        let payload = Data("""
        {"error":"invalid_grant","error_description":"Refresh token expired"}
        """.utf8)

        let parsed = LinearAuthService.parseOAuthError(
            data: payload,
            statusCode: 400,
            context: .refresh
        )

        XCTAssertEqual(parsed.userMessage, "Refresh token expired")
        XCTAssertTrue(parsed.logMessage.contains("invalid_grant"))
    }

    func testParseOAuthErrorFallsBackToErrorField() throws {
        let payload = Data("""
        {"error":"invalid_client"}
        """.utf8)

        let parsed = LinearAuthService.parseOAuthError(
            data: payload,
            statusCode: 401,
            context: .exchange
        )

        XCTAssertEqual(parsed.userMessage, "invalid_client")
        XCTAssertTrue(parsed.logMessage.contains("Token exchange failed"))
    }

    func testParseOAuthErrorForNonJSONDoesNotEchoBody() throws {
        let payload = Data("access_token=should_not_be_logged".utf8)

        let parsed = LinearAuthService.parseOAuthError(
            data: payload,
            statusCode: 500,
            context: .exchange
        )

        XCTAssertEqual(parsed.userMessage, "Failed to exchange code for token (HTTP 500)")
        XCTAssertTrue(parsed.logMessage.contains("non-JSON body"))
        XCTAssertFalse(parsed.logMessage.contains("access_token=should_not_be_logged"))
    }
}
