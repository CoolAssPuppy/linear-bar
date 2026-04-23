import XCTest
@testable import LinearBar

/// Confirms the typed `IssueState.kind` / `isOpen` accessors agree with the
/// raw `type` strings used elsewhere in the app. These predicates are load-
/// bearing for Mine's rebuildOpen and Pulse's at-risk filtering.
final class IssueStateTests: XCTestCase {
    func testKindRecognizesCanonicalValues() {
        XCTAssertEqual(IssueState(name: "Backlog", type: "backlog").kind, .backlog)
        XCTAssertEqual(IssueState(name: "Todo", type: "unstarted").kind, .unstarted)
        XCTAssertEqual(IssueState(name: "In Progress", type: "started").kind, .started)
        XCTAssertEqual(IssueState(name: "Done", type: "completed").kind, .completed)
        XCTAssertEqual(IssueState(name: "Canceled", type: "canceled").kind, .canceled)
        XCTAssertEqual(IssueState(name: "Triage", type: "triage").kind, .triage)
    }

    func testKindReturnsNilForUnknownType() {
        XCTAssertNil(IssueState(name: "???", type: "someNewState").kind)
    }

    func testIsOpenTrueForEveryNonTerminalKind() {
        for type in ["backlog", "triage", "unstarted", "started"] {
            XCTAssertTrue(IssueState(name: type, type: type).isOpen, "\(type) should be open")
        }
    }

    func testIsOpenFalseForTerminalKinds() {
        XCTAssertFalse(IssueState(name: "Done", type: "completed").isOpen)
        XCTAssertFalse(IssueState(name: "Canceled", type: "canceled").isOpen)
    }

    /// Unknown state types default to open. Keeps the UI visible even when
    /// Linear ships a new state classification we haven't mapped yet.
    func testIsOpenDefaultsOpenOnUnknownKind() {
        XCTAssertTrue(IssueState(name: "Custom", type: "somethingNew").isOpen)
    }
}
