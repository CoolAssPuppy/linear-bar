import SwiftUI
import XCTest
@testable import LinearBar

final class ColorHexTests: XCTestCase {

    func testSixCharacterHexDecodesToRGB() {
        let color = Color(hex: "#FF0033")
        let components = color.nsColor.cgColor.components ?? []
        XCTAssertEqual(components.count, 4)
        XCTAssertEqual(components[0], 1.0, accuracy: 0.01)
        XCTAssertEqual(components[1], 0.0, accuracy: 0.01)
        XCTAssertEqual(components[2], 0.2, accuracy: 0.01)
        XCTAssertEqual(components[3], 1.0, accuracy: 0.01)
    }

    func testHexWithoutLeadingHashWorks() {
        let color = Color(hex: "FF0033")
        let components = color.nsColor.cgColor.components ?? []
        XCTAssertEqual(components[0], 1.0, accuracy: 0.01)
        XCTAssertEqual(components[2], 0.2, accuracy: 0.01)
    }

    func testEightCharacterHexDecodesAlpha() {
        let color = Color(hex: "#80FFFFFF")
        let components = color.nsColor.cgColor.components ?? []
        XCTAssertEqual(components[3], Double(0x80) / 255.0, accuracy: 0.01)
    }
}

private extension Color {
    /// Small bridge so we can read CGColor components in tests. SwiftUI's
    /// Color has no public color-component API on macOS.
    var nsColor: NSColor { NSColor(self) }
}
