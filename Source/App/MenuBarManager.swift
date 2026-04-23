import AppKit

/// Manages the menu bar status item and its icon state.
///
/// State priority (high → low): offline, needsAuth, syncing, urgent, unread, quiet.
@MainActor
class MenuBarManager {
    private(set) var statusItem: NSStatusItem?

    /// True while a refresh is in flight. Higher in priority than auth/unread
    /// states because it is visible feedback on a user-triggered action.
    var isSyncing: Bool = false {
        didSet {
            if isSyncing != oldValue {
                updateIcon()
            }
        }
    }

    /// True when the system has reported no network. The app reports offline
    /// separately from HTTP errors because the icon should change before any
    /// query fires.
    var isOffline: Bool = false {
        didSet {
            if isOffline != oldValue {
                updateIcon()
            }
        }
    }

    /// Current unread notification count pulled from `notificationsUnreadCount`.
    /// A number > 0 drives either `.unread` or `.urgent` depending on
    /// `hasUrgentAlerts`.
    var unreadCount: Int = 0 {
        didSet {
            if unreadCount != oldValue {
                updateIcon()
            }
        }
    }

    /// Set when at least one SLA breach is imminent or the viewer has been
    /// pinged about an urgent issue. Promotes the icon to `.urgent`.
    var hasUrgentAlerts: Bool = false {
        didSet {
            if hasUrgentAlerts != oldValue {
                updateIcon()
            }
        }
    }

    func setup(target: AnyObject, action: Selector) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = MenuBarIconRenderer.image(for: .quiet)
            button.action = action
            button.target = target
            updateIcon()
        }
    }

    func updateIcon() {
        guard let button = statusItem?.button else { return }

        #if DEBUG
        if CommandLine.arguments.contains("--uitesting") {
            button.image = MenuBarIconRenderer.image(for: .unread(count: 3))
            return
        }
        #endif

        let state = currentState()
        button.image = MenuBarIconRenderer.image(for: state)
        button.toolTip = tooltip(for: state)
    }

    // MARK: - State resolution

    private func currentState() -> MenuBarIconState {
        if isOffline {
            return .offline
        }

        let hasAuthIssues = AppSettings.shared.accounts.contains { $0.authStatus != .valid }
        if hasAuthIssues {
            return .needsAuth
        }

        if isSyncing {
            return .syncing
        }

        if hasUrgentAlerts && unreadCount > 0 {
            return .urgent(count: unreadCount)
        }

        if unreadCount > 0 {
            return .unread(count: unreadCount)
        }

        return .quiet
    }

    private func tooltip(for state: MenuBarIconState) -> String {
        switch state {
        case .quiet:
            return "Linear Bar"
        case .unread(let count):
            return count == 1 ? "1 unread notification" : "\(count) unread notifications"
        case .urgent(let count):
            return count == 1 ? "1 urgent notification" : "\(count) urgent notifications"
        case .syncing:
            return "Syncing…"
        case .needsAuth:
            return "Sign in again to continue"
        case .offline:
            return "Offline"
        }
    }
}
