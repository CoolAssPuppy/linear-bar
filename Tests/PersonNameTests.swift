import XCTest
@testable import LinearBar

final class PersonNameTests: XCTestCase {
    func testTwoWordName() {
        XCTAssertEqual(PersonName.initials(from: "Maya Chen"), "MC")
    }

    func testSingleWordName() {
        XCTAssertEqual(PersonName.initials(from: "Linear"), "L")
    }

    func testMoreThanTwoWordsOnlyUsesFirstTwo() {
        XCTAssertEqual(PersonName.initials(from: "Jean Luc Picard"), "JL")
    }

    func testEmptyAndNil() {
        XCTAssertEqual(PersonName.initials(from: nil), "—")
        XCTAssertEqual(PersonName.initials(from: ""), "—")
    }

    func testTrimsToUppercase() {
        XCTAssertEqual(PersonName.initials(from: "maya chen"), "MC")
    }
}
