import XCTest
@testable import LinearBar

/// Priority order for the menu bar icon:
/// offline > needsAuth > syncing > urgent > unread > quiet. Verified by
/// inspecting `currentState()` directly — we avoid bringing up an
/// NSStatusItem (which requires the main run loop and would fail
/// headlessly in xctest).
@MainActor
final class MenuBarManagerTests: XCTestCase {

    override func setUp() async throws {
        try await super.setUp()
        // Tests read `AppSettings.shared.accounts` to check auth state;
        // reset it to empty so "needsAuth" only fires when we set it.
        AppSettings.shared.accounts = []
    }

    func testResolvesQuietByDefault() {
        let manager = MenuBarManager()
        XCTAssertEqual(manager.currentState(), .quiet)
    }

    func testUnreadOverridesQuiet() {
        let manager = MenuBarManager()
        manager.unreadCount = 5
        XCTAssertEqual(manager.currentState(), .unread(count: 5))
    }

    func testUrgentWinsOverUnread() {
        let manager = MenuBarManager()
        manager.unreadCount = 5
        manager.hasUrgentAlerts = true
        XCTAssertEqual(manager.currentState(), .urgent(count: 5))
    }

    func testSyncingWinsOverUrgent() {
        let manager = MenuBarManager()
        manager.unreadCount = 5
        manager.hasUrgentAlerts = true
        manager.isSyncing = true
        XCTAssertEqual(manager.currentState(), .syncing)
    }

    func testOfflineWinsOverEverything() {
        let manager = MenuBarManager()
        manager.unreadCount = 5
        manager.hasUrgentAlerts = true
        manager.isSyncing = true
        manager.isOffline = true
        XCTAssertEqual(manager.currentState(), .offline)
    }
}
