import Foundation
import Combine
import AppKit
import os.log

/// Application settings with iCloud synchronization
@MainActor
class AppSettings: ObservableObject {
    static let shared = AppSettings()

    let iCloudStore = NSUbiquitousKeyValueStore.default

    // MARK: - Published Properties

    @Published var accounts: [LinearAccount] {
        didSet {
            saveAccounts()
            NotificationCenter.default.post(name: .accountsDidUpdate, object: nil)
        }
    }

    @Published var refreshInterval: RefreshInterval {
        didSet {
            saveSetting(refreshInterval.rawValue, forKey: "refreshInterval")
        }
    }

    @Published var launchAtLogin: Bool {
        didSet {
            saveSetting(launchAtLogin, forKey: "launchAtLogin")
        }
    }

    @Published var defaultTab: DefaultTab {
        didSet {
            saveSetting(defaultTab.rawValue, forKey: "defaultTab")
        }
    }

    @Published var showCompletedItems: Bool {
        didSet {
            saveSetting(showCompletedItems, forKey: "showCompletedItems")
        }
    }

    @Published var showCanceledItems: Bool {
        didSet {
            saveSetting(showCanceledItems, forKey: "showCanceledItems")
        }
    }

    @Published var sortOrder: SortOrder {
        didSet {
            saveSetting(sortOrder.rawValue, forKey: "sortOrder")
        }
    }

    @Published var selectedTeamId: String? {
        didSet {
            saveLocalSetting(selectedTeamId ?? "", forKey: "selectedTeamId")
        }
    }

    @Published var selectedTeamKey: String? {
        didSet {
            saveLocalSetting(selectedTeamKey ?? "", forKey: "selectedTeamKey")
        }
    }

    // MARK: - Initialization

    private init() {
        self.accounts = []

        iCloudStore.synchronize()

        let refreshRaw = iCloudStore.string(forKey: "refreshInterval")
            ?? UserDefaults.standard.string(forKey: "refreshInterval")
            ?? RefreshInterval.fifteenMinutes.rawValue
        self.refreshInterval = RefreshInterval(rawValue: refreshRaw) ?? .fifteenMinutes

        self.launchAtLogin = iCloudStore.object(forKey: "launchAtLogin") as? Bool
            ?? UserDefaults.standard.object(forKey: "launchAtLogin") as? Bool
            ?? false

        let defaultTabRaw = iCloudStore.string(forKey: "defaultTab")
            ?? UserDefaults.standard.string(forKey: "defaultTab")
            ?? DefaultTab.inbox.rawValue
        self.defaultTab = DefaultTab(rawValue: defaultTabRaw) ?? .inbox

        self.showCompletedItems = iCloudStore.object(forKey: "showCompletedItems") as? Bool
            ?? UserDefaults.standard.object(forKey: "showCompletedItems") as? Bool
            ?? true

        self.showCanceledItems = iCloudStore.object(forKey: "showCanceledItems") as? Bool
            ?? UserDefaults.standard.object(forKey: "showCanceledItems") as? Bool
            ?? false

        let sortOrderRaw = iCloudStore.string(forKey: "sortOrder")
            ?? UserDefaults.standard.string(forKey: "sortOrder")
            ?? SortOrder.updatedNewest.rawValue
        self.sortOrder = SortOrder(rawValue: sortOrderRaw) ?? .updatedNewest

        let teamId = UserDefaults.standard.string(forKey: "selectedTeamId")
        self.selectedTeamId = teamId?.isEmpty == false ? teamId : nil

        let teamKey = UserDefaults.standard.string(forKey: "selectedTeamKey")
        self.selectedTeamKey = teamKey?.isEmpty == false ? teamKey : nil

        loadAccounts()
        syncAllSettingsFromiCloudToUserDefaults()
        setupiCloudSync()
    }

    // MARK: - Account Management

    func addAccount(_ account: LinearAccount) {
        if !accounts.contains(where: { $0.id == account.id }) {
            accounts.append(account)
        }
    }

    func removeAccount(_ account: LinearAccount) {
        accounts.removeAll { $0.id == account.id }
        _ = KeychainService.shared.deleteAllTokens(forAccount: account.email)
    }

    func updateAccount(_ account: LinearAccount) {
        if let index = accounts.firstIndex(where: { $0.id == account.id }) {
            accounts[index] = account
        }
    }

    func account(forEmail email: String) -> LinearAccount? {
        accounts.first { $0.email == email }
    }

    func setAccountColor(_ color: String, forAccount email: String) {
        if let index = accounts.firstIndex(where: { $0.email == email }) {
            accounts[index].color = color
        }
    }

    // MARK: - Computed Properties

    /// First enabled account with a valid access token. Every popover tab
    /// needs this to kick off a GraphQL query, so centralizing the predicate
    /// avoids scattering the same `.first(where:)` across views.
    var primaryValidAccount: LinearAccount? {
        accounts.first { $0.isEnabled && $0.authStatus == .valid }
    }

    var primaryAccountColor: String? {
        primaryValidAccount?.color
    }

    var primaryOrganizationSlug: String? {
        primaryValidAccount?.organizationSlug
    }

    // MARK: - Private Methods

    private func loadAccounts() {
        if let data = UserDefaults.standard.data(forKey: "accounts") {
            do {
                var decoded = try JSONDecoder().decode([LinearAccount].self, from: data)

                for i in 0..<decoded.count {
                    let account = decoded[i]
                    let hasAccessToken = KeychainService.shared.retrieveAccessToken(forAccount: account.email) != nil

                    if !hasAccessToken {
                        decoded[i].authStatus = .needsAuth
                        AppLogger.privateInfo("Account \(account.email) has no local tokens - marked as needsAuth", log: AppLogger.settings)
                    } else if decoded[i].authStatus == .needsAuth {
                        decoded[i].authStatus = .valid
                        AppLogger.privateInfo("Account \(account.email) now has tokens - marked as valid", log: AppLogger.settings)
                    }
                }

                self.accounts = decoded
                AppLogger.info("Successfully loaded \(decoded.count) accounts", log: AppLogger.settings)
            } catch {
                AppLogger.error("Error loading accounts", log: AppLogger.settings, error: error)
            }
        } else {
            AppLogger.debug("No account data found in UserDefaults", log: AppLogger.settings)
        }
    }

    private func saveAccounts() {
        #if DEBUG
        if CommandLine.arguments.contains("--uitesting") {
            AppLogger.debug("UI testing mode - skipping account persistence", log: AppLogger.settings)
            return
        }
        #endif

        if let encoded = try? JSONEncoder().encode(accounts) {
            UserDefaults.standard.set(encoded, forKey: "accounts")
            AppLogger.debug("Saved \(accounts.count) accounts", log: AppLogger.settings)
        }
    }
}
