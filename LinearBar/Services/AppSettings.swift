import Foundation
import Combine
import AppKit
import os.log

/// Application settings with iCloud synchronization
@MainActor
class AppSettings: ObservableObject {
    static let shared = AppSettings()

    private let iCloudStore = NSUbiquitousKeyValueStore.default

    // MARK: - Published Properties

    @Published var accounts: [LinearAccount] {
        didSet {
            saveAccounts()
            NotificationCenter.default.post(name: .accountsDidUpdate, object: nil)
        }
    }

    @Published var defaultViewMode: ViewMode {
        didSet {
            saveSetting(defaultViewMode.rawValue, forKey: "defaultViewMode")
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

    // MARK: - Initialization

    private init() {
        self.accounts = []

        // Sync with iCloud first
        iCloudStore.synchronize()

        // Load settings from iCloud or fallback to UserDefaults
        let viewModeRaw = iCloudStore.string(forKey: "defaultViewMode")
            ?? UserDefaults.standard.string(forKey: "defaultViewMode")
            ?? ViewMode.createdByMe.rawValue
        self.defaultViewMode = ViewMode(rawValue: viewModeRaw) ?? .createdByMe

        let refreshRaw = iCloudStore.string(forKey: "refreshInterval")
            ?? UserDefaults.standard.string(forKey: "refreshInterval")
            ?? RefreshInterval.fifteenMinutes.rawValue
        self.refreshInterval = RefreshInterval(rawValue: refreshRaw) ?? .fifteenMinutes

        self.launchAtLogin = iCloudStore.object(forKey: "launchAtLogin") as? Bool
            ?? UserDefaults.standard.object(forKey: "launchAtLogin") as? Bool
            ?? false

        let defaultTabRaw = iCloudStore.string(forKey: "defaultTab")
            ?? UserDefaults.standard.string(forKey: "defaultTab")
            ?? DefaultTab.favorites.rawValue
        self.defaultTab = DefaultTab(rawValue: defaultTabRaw) ?? .favorites

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

    /// Sets a custom color for an account
    func setAccountColor(_ color: String, forAccount email: String) {
        if let index = accounts.firstIndex(where: { $0.email == email }) {
            accounts[index].color = color
        }
    }

    // MARK: - Private Methods

    private func loadAccounts() {
        if let data = UserDefaults.standard.data(forKey: "accounts") {
            do {
                var decoded = try JSONDecoder().decode([LinearAccount].self, from: data)

                // Check if each account has local OAuth tokens
                for i in 0..<decoded.count {
                    let account = decoded[i]
                    let hasAccessToken = KeychainService.shared.retrieveAccessToken(forAccount: account.email) != nil

                    // If account has no local tokens, mark as needing auth
                    if !hasAccessToken {
                        decoded[i].authStatus = .needsAuth
                        AppLogger.info("Account \(account.email) has no local tokens - marked as needsAuth", log: AppLogger.settings)
                    } else if decoded[i].authStatus == .needsAuth {
                        // If account was marked as needsAuth but now has tokens, mark as valid
                        decoded[i].authStatus = .valid
                        AppLogger.info("Account \(account.email) now has tokens - marked as valid", log: AppLogger.settings)
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
        if let encoded = try? JSONEncoder().encode(accounts) {
            UserDefaults.standard.set(encoded, forKey: "accounts")
            AppLogger.debug("Saved \(accounts.count) accounts", log: AppLogger.settings)
        }
    }

    private func saveSetting<T>(_ value: T, forKey key: String) {
        // Save to local UserDefaults
        UserDefaults.standard.set(value, forKey: key)

        // Save to iCloud
        iCloudStore.set(value, forKey: key)
        iCloudStore.synchronize()
    }

    private func syncAllSettingsFromiCloudToUserDefaults() {
        let settingsKeys = ["defaultViewMode", "refreshInterval", "launchAtLogin", "defaultTab", "showCompletedItems", "showCanceledItems", "sortOrder"]

        for key in settingsKeys {
            if let value = iCloudStore.object(forKey: key) {
                UserDefaults.standard.set(value, forKey: key)
            }
        }
    }

    private func setupiCloudSync() {
        // Observe iCloud changes from other devices
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(iCloudStoreDidChange),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: iCloudStore
        )

        // Synchronize with iCloud
        iCloudStore.synchronize()
    }

    @objc private func iCloudStoreDidChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let keys = userInfo[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String] else {
            return
        }

        // Update local settings from iCloud
        for key in keys {
            if let value = iCloudStore.object(forKey: key) {
                UserDefaults.standard.set(value, forKey: key)
            }
        }

        // Reload affected settings
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            if keys.contains("defaultViewMode") {
                let viewModeRaw = UserDefaults.standard.string(forKey: "defaultViewMode") ?? ViewMode.createdByMe.rawValue
                self.defaultViewMode = ViewMode(rawValue: viewModeRaw) ?? .createdByMe
            }
            if keys.contains("refreshInterval") {
                let refreshRaw = UserDefaults.standard.string(forKey: "refreshInterval") ?? RefreshInterval.fifteenMinutes.rawValue
                self.refreshInterval = RefreshInterval(rawValue: refreshRaw) ?? .fifteenMinutes
            }
            if keys.contains("launchAtLogin") {
                self.launchAtLogin = UserDefaults.standard.bool(forKey: "launchAtLogin")
            }
            if keys.contains("defaultTab") {
                let tabRaw = UserDefaults.standard.string(forKey: "defaultTab") ?? DefaultTab.favorites.rawValue
                self.defaultTab = DefaultTab(rawValue: tabRaw) ?? .favorites
            }
            if keys.contains("showCompletedItems") {
                self.showCompletedItems = UserDefaults.standard.bool(forKey: "showCompletedItems")
            }
            if keys.contains("showCanceledItems") {
                self.showCanceledItems = UserDefaults.standard.bool(forKey: "showCanceledItems")
            }
            if keys.contains("sortOrder") {
                let sortRaw = UserDefaults.standard.string(forKey: "sortOrder") ?? SortOrder.updatedNewest.rawValue
                self.sortOrder = SortOrder(rawValue: sortRaw) ?? .updatedNewest
            }
        }
    }
}

// MARK: - Enums

enum ViewMode: String, CaseIterable, Identifiable {
    case createdByMe = "Created by Me"
    case assignedToMe = "Assigned to Me"
    case teamItems = "Team"

    var id: String { rawValue }
}

enum RefreshInterval: String, CaseIterable, Identifiable {
    case manual = "Manual Only"
    case fiveMinutes = "Every 5 Minutes"
    case fifteenMinutes = "Every 15 Minutes"
    case thirtyMinutes = "Every 30 Minutes"
    case oneHour = "Every Hour"

    var id: String { rawValue }

    var seconds: TimeInterval? {
        switch self {
        case .manual:
            return nil
        case .fiveMinutes:
            return 5 * 60
        case .fifteenMinutes:
            return 15 * 60
        case .thirtyMinutes:
            return 30 * 60
        case .oneHour:
            return 60 * 60
        }
    }
}

enum DefaultTab: String, CaseIterable, Identifiable {
    case favorites = "Favorites"
    case recent = "Recent"
    case search = "Search"

    var id: String { rawValue }
}

enum SortOrder: String, CaseIterable, Identifiable {
    case createdNewest = "Created Date, Newest First"
    case createdOldest = "Created Date, Oldest First"
    case updatedNewest = "Updated Date, Newest First"
    case updatedOldest = "Updated Date, Oldest First"

    var id: String { rawValue }
}

// MARK: - Notification Names

extension Notification.Name {
    static let accountsDidUpdate = Notification.Name("accountsDidUpdate")
    static let settingsRequested = Notification.Name("settingsRequested")
    static let refreshAllData = Notification.Name("refreshAllData")
}
