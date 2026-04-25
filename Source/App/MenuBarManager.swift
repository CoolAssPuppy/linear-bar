import AppKit
import Combine

/// Manages the menu bar status item and its icon state.
///
/// State priority (high → low): offline, needsAuth, syncing, urgent, unread, quiet.
@MainActor
class MenuBarManager {
    private(set) var statusItem: NSStatusItem?

    /// Last applied icon state, used to suppress redundant redraws when
    /// multiple input properties change but resolve to the same visual state
    /// (e.g. unread count ticking while `isOffline` is already true).
    private var lastAppliedState: MenuBarIconState?

    /// Subscription to `UnreadInboxStore.total`. Held strongly so the store's
    /// publisher keeps emitting; cancelled in `applicationWillTerminate` via
    /// `tearDown()`.
    private var unreadCancellable: AnyCancellable?

    var isSyncing: Bool = false {
        didSet { if isSyncing != oldValue { updateIcon() } }
    }

    var isOffline: Bool = false {
        didSet { if isOffline != oldValue { updateIcon() } }
    }

    var unreadCount: Int = 0 {
        didSet { if unreadCount != oldValue { updateIcon() } }
    }

    var hasUrgentAlerts: Bool = false {
        didSet { if hasUrgentAlerts != oldValue { updateIcon() } }
    }

    func setup(target: AnyObject, action: Selector) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = MenuBarIconRenderer.image(for: .quiet)
            button.action = action
            button.target = target
            updateIcon()
        }

        // Mirror the aggregated unread total into our published count. The
        // store handles polling + per-workspace toggle filtering — we just
        // surface whatever it computed.
        unreadCancellable = UnreadInboxStore.shared.$total
            .receive(on: DispatchQueue.main)
            .sink { [weak self] count in
                self?.unreadCount = count
            }
    }

    func tearDown() {
        unreadCancellable?.cancel()
        unreadCancellable = nil
    }

    func updateIcon() {
        guard let button = statusItem?.button else { return }

        #if DEBUG
        if CommandLine.arguments.contains("--uitesting") {
            apply(.unread(count: 3), to: button)
            return
        }
        #endif

        apply(currentState(), to: button)
    }

    private func apply(_ state: MenuBarIconState, to button: NSStatusBarButton) {
        guard state != lastAppliedState else { return }
        lastAppliedState = state
        button.image = MenuBarIconRenderer.image(for: state)
        button.toolTip = tooltip(for: state)
    }

    // MARK: - State resolution

    /// Exposed as `internal` so unit tests can verify the state priority
    /// without bringing up an NSStatusItem. Not part of the public surface.
    func currentState() -> MenuBarIconState {
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
            return "Menu Bar for Linear"
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
