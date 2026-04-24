import XCTest
@testable import LinearBar

final class SafeExternalURLTests: XCTestCase {

    func testLinearURLAcceptsCanonicalHost() {
        let url = SafeExternalURL.linearURL(from: "https://linear.app/team/ENG/new")
        XCTAssertEqual(url?.host, "linear.app")
    }

    func testLinearURLRejectsNonHttpsScheme() {
        XCTAssertNil(SafeExternalURL.linearURL(from: "http://linear.app/issue/ABC-1"))
        XCTAssertNil(SafeExternalURL.linearURL(from: "javascript:alert(1)"))
        XCTAssertNil(SafeExternalURL.linearURL(from: "file:///tmp/owned"))
    }

    func testLinearURLRejectsLookalikeHosts() {
        XCTAssertNil(SafeExternalURL.linearURL(from: "https://linear.app.evil.example/issue/ABC-1"))
        XCTAssertNil(SafeExternalURL.linearURL(from: "https://evil.example/linear.app"))
    }

    func testLinearPathBuilderPercentEncodesUntrustedSegments() {
        let built = SafeExternalURL.linearURL(
            orgSlug: "my org",
            pathComponents: ["team", "ios core", "new?foo=bar#frag"]
        )
        let value = built?.absoluteString ?? ""
        XCTAssertTrue(value.hasPrefix("https://linear.app/"))
        XCTAssertTrue(value.contains("my%20org"))
        XCTAssertTrue(value.contains("ios%20core"))
        XCTAssertTrue(value.contains("new%3Ffoo=bar%23frag"))
    }

    func testHTTPSURLAllowsRemoteHttpsOnly() {
        XCTAssertNotNil(SafeExternalURL.httpsURL(from: "https://cdn.linear.app/avatar.png"))
        XCTAssertNil(SafeExternalURL.httpsURL(from: "http://cdn.linear.app/avatar.png"))
        XCTAssertNil(SafeExternalURL.httpsURL(from: "data:text/plain,hi"))
    }
}
