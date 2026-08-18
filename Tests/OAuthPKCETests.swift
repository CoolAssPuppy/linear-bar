import XCTest
@testable import LinearBar

final class OAuthPKCETests: XCTestCase {
    func testChallengeMatchesRFC7636Example() {
        let verifier = "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"

        XCTAssertEqual(
            OAuthPKCE.challenge(for: verifier),
            "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM"
        )
    }

    func testGeneratedVerifierUsesURLSafeCharactersAndRequiredLength() throws {
        let verifier = try OAuthPKCE.generateVerifier()

        XCTAssertGreaterThanOrEqual(verifier.count, 43)
        XCTAssertLessThanOrEqual(verifier.count, 128)
        XCTAssertNotNil(verifier.range(of: "^[A-Za-z0-9._~-]+$", options: .regularExpression))
    }
}
