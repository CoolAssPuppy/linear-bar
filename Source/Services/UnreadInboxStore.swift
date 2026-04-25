import Foundation
import Combine

/// Single source of truth for the menu bar's unread Inbox total. Aggregates
/// `notificationsUnreadCount` across every enabled workspace whose user has
/// the per-workspace toggle on, then publishes the sum.
///
/// `MenuBarManager` mirrors `total` into its icon state so the count appears
/// to the right of the planet glyph; `MenuBarView` reads `total` to drive the
/// badge next to the Inbox tab. Centralizing the fetch here means we don't
/// pay the GraphQL roundtrip twice for the same number.
@MainActor
final class UnreadInboxStore: ObservableObject {
    static let shared = UnreadInboxStore()

    /// Sum of unread Inbox counts across all opted-in workspaces.
    @Published private(set) var total: Int = 0

    /// Per-account most-recent count, keyed by email. Useful for debugging
    /// and surfacing per-workspace badges later.
    @Published private(set) var perAccount: [String: Int] = [:]

    private var pollTimer: Timer?
    private var inFlight: Task<Void, Never>?

    /// Polling cadence. Linear's `notificationsUnreadCount` is a cheap
    /// scalar — every 90 seconds keeps the badge fresh without hammering
    /// the API. Refresh-all from the popover bottom bar also triggers a
    /// fetch via the `refreshAllData` notification.
    private static let pollInterval: TimeInterval = 90

    /// Tracks whether the notification observers have been wired up. We
    /// can't register them in `init()` because `AppSettings.loadAccounts()`
    /// posts `.accountsDidUpdate` from inside `AppSettings.shared`'s own
    /// dispatch_once — re-entering this store on the same thread would
    /// then read `AppSettings.shared.accounts` and recursively lock libdispatch.
    /// `start()` registers observers after AppDelegate has finished
    /// `applicationDidFinishLaunching`, by which point AppSettings has
    /// fully published.
    private var observersRegistered = false

    private init() {}

    deinit {
        // swiftlint:disable:next notification_center_detachment
        NotificationCenter.default.removeObserver(self)
    }

    func start() {
        stop()
        registerObserversIfNeeded()
        // Fire once immediately so the badge isn't blank at launch, then
        // schedule the recurring tick.
        refresh()

        let timer = Timer.scheduledTimer(withTimeInterval: Self.pollInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.refresh() }
        }
        pollTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    func stop() {
        pollTimer?.invalidate()
        pollTimer = nil
        inFlight?.cancel()
        inFlight = nil
    }

    private func registerObserversIfNeeded() {
        guard !observersRegistered else { return }
        observersRegistered = true
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAccountsChanged),
            name: .accountsDidUpdate,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRefreshAll),
            name: .refreshAllData,
            object: nil
        )
    }

    @objc private func handleAccountsChanged() {
        refresh()
    }

    @objc private func handleRefreshAll() {
        refresh()
    }

    func refresh() {
        let snapshot = AppSettings.shared.accounts.filter {
            $0.isEnabled && $0.authStatus == .valid && $0.showUnreadInMenuBar
        }

        // Drop accounts that just had their toggle flipped off so the per-
        // account map doesn't keep stale numbers and contribute orphan
        // counts on the next aggregation.
        let allowed = Set(snapshot.map { $0.email })
        perAccount = perAccount.filter { allowed.contains($0.key) }
        total = perAccount.values.reduce(0, +)

        guard !snapshot.isEmpty else {
            total = 0
            perAccount = [:]
            return
        }

        inFlight?.cancel()
        inFlight = Task { @MainActor in
            await withTaskGroup(of: (String, Int)?.self) { group in
                for account in snapshot {
                    guard let token = KeychainService.shared.retrieveAccessToken(forAccount: account.email) else {
                        continue
                    }
                    group.addTask {
                        do {
                            let count = try await LinearAPI.shared.fetchUnreadNotificationCount(
                                accessToken: token,
                                accountEmail: account.email
                            )
                            return (account.email, count)
                        } catch {
                            AppLogger.privateInfo(
                                "Unread count fetch failed for \(account.email): \(error.localizedDescription)",
                                log: AppLogger.app
                            )
                            return nil
                        }
                    }
                }

                var fresh: [String: Int] = [:]
                for await result in group {
                    if let (email, count) = result, allowed.contains(email) {
                        fresh[email] = count
                    }
                }

                if Task.isCancelled { return }
                perAccount = fresh
                total = fresh.values.reduce(0, +)
            }
        }
    }
}
