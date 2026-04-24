import Foundation
import Combine

/// Shared cache of the viewer's teams. Every popover tab needs the same
/// list — keeping it in one store avoids each tab issuing its own
/// `fetchTeams` round-trip and avoids drift between tabs' menus.
///
/// The selected team id lives in `AppSettings.selectedTeamId` so the choice
/// persists across relaunches. A nil value means "All teams."
@MainActor
final class TeamsStore: ObservableObject {
    static let shared = TeamsStore()

    @Published private(set) var teams: [Team] = []
    @Published private(set) var isLoading = false

    private var hasLoadedOnce = false

    private init() {}

    /// Fetches the team list if we haven't yet. Idempotent; subsequent calls
    /// are no-ops unless `force` is set.
    func loadIfNeeded(force: Bool = false) {
        if !force, hasLoadedOnce { return }
        hasLoadedOnce = true

        if TestDataProvider.isUITesting {
            teams = TestDataProvider.getTeams()
            return
        }

        guard let account = AppSettings.shared.primaryValidAccount,
              let token = KeychainService.shared.retrieveAccessToken(forAccount: account.email) else {
            return
        }

        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                let fetched = try await LinearAPI.shared.fetchTeams(
                    accessToken: token,
                    accountEmail: account.email
                )
                teams = fetched
            } catch {
                AppLogger.error("TeamsStore load failed", log: AppLogger.api, error: error)
            }
        }
    }
}
