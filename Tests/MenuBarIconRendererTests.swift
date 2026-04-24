import XCTest
@testable import LinearBar

final class MenuBarIconRendererTests: XCTestCase {

    /// Quiet / unread / syncing / offline are template variants so the menu
    /// bar can re-tint them for light / dark bars. Urgent and needsAuth
    /// carry semantic color and must not be templates.
    func testTemplateFlagsPerState() {
        XCTAssertTrue(MenuBarIconRenderer.image(for: .quiet).isTemplate)
        XCTAssertTrue(MenuBarIconRenderer.image(for: .unread(count: 3)).isTemplate)
        XCTAssertTrue(MenuBarIconRenderer.image(for: .syncing).isTemplate)
        XCTAssertTrue(MenuBarIconRenderer.image(for: .offline).isTemplate)

        XCTAssertFalse(MenuBarIconRenderer.image(for: .urgent(count: 2)).isTemplate)
        XCTAssertFalse(MenuBarIconRenderer.image(for: .needsAuth).isTemplate)
    }

    /// `image(for:)` caches by state. The same state should return the same
    /// NSImage instance, which is how the manager avoids redrawing on every
    /// tick even when inputs haven't changed.
    func testIdenticalStatesReturnIdenticalInstances() {
        let first = MenuBarIconRenderer.image(for: .unread(count: 7))
        let second = MenuBarIconRenderer.image(for: .unread(count: 7))
        XCTAssertTrue(first === second)
    }

    /// Different counts resolve to different states and therefore different
    /// cache entries — verifies the state value is actually hashed.
    func testDifferentCountsReturnDifferentInstances() {
        let three = MenuBarIconRenderer.image(for: .unread(count: 3))
        let four = MenuBarIconRenderer.image(for: .unread(count: 4))
        XCTAssertFalse(three === four)
    }

    func testAllStatesRenderAtExpectedSize() {
        let states: [MenuBarIconState] = [
            .quiet,
            .unread(count: 1),
            .urgent(count: 1),
            .syncing,
            .needsAuth,
            .offline
        ]
        for state in states {
            let size = MenuBarIconRenderer.image(for: state).size
            XCTAssertEqual(size.width, 22, "state \(state)")
            XCTAssertEqual(size.height, 18, "state \(state)")
        }
    }
}
