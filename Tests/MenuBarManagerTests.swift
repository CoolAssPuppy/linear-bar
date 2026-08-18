import XCTest
@testable import LinearBar

/// Priority order for the menu bar icon:
/// offline > needsAuth > syncing > urgent > unread > quiet. Verified by
/// inspecting `currentState()` directly — we avoid bringing up an
/// NSStatusItem (which requires the main run loop and would fail
/// headlessly in xctest).
@MainActor
final class MenuBarManagerTests: XCTestCase {

    func testResolvesQuietByDefault() {
        let manager = makeManager()
        XCTAssertEqual(manager.currentState(), .quiet)
    }

    func testUnreadOverridesQuiet() {
        let manager = makeManager()
        manager.unreadCount = 5
        XCTAssertEqual(manager.currentState(), .unread(count: 5))
    }

    func testUnreadSettingCanHideTheCount() {
        let suiteName = "MenuBarManagerTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Could not create test preferences")
            return
        }
        defaults.set(false, forKey: "showUnreadCount")
        let manager = MenuBarManager(defaults: defaults, hasAuthIssues: { false })
        manager.unreadCount = 5

        XCTAssertEqual(manager.currentState(), .quiet)
    }

    func testUrgentWinsOverUnread() {
        let manager = makeManager()
        manager.unreadCount = 5
        manager.hasUrgentAlerts = true
        XCTAssertEqual(manager.currentState(), .urgent(count: 5))
    }

    func testSyncingWinsOverUrgent() {
        let manager = makeManager()
        manager.unreadCount = 5
        manager.hasUrgentAlerts = true
        manager.isSyncing = true
        XCTAssertEqual(manager.currentState(), .syncing)
    }

    func testOfflineWinsOverEverything() {
        let manager = makeManager()
        manager.unreadCount = 5
        manager.hasUrgentAlerts = true
        manager.isSyncing = true
        manager.isOffline = true
        XCTAssertEqual(manager.currentState(), .offline)
    }

    private func makeManager() -> MenuBarManager {
        MenuBarManager(defaults: .standard, hasAuthIssues: { false })
    }
}
