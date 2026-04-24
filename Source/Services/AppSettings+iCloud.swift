import Foundation

extension AppSettings {

    /// Keys written to iCloud KVS when sync is enabled. UserDefaults is
    /// always written; the iCloud write is skipped when the master toggle
    /// is off so the user can keep settings device-local if they want.
    static let iCloudPreferenceKeys = [
        "refreshInterval",
        "launchAtLogin",
        "defaultTab",
        "showCompletedItems",
        "showCanceledItems",
        "sortOrder",
        "demoModeEnabled"
    ]

    /// `accounts` is a JSON blob — also synced when the toggle is on, so
    /// workspaces the user connects on one machine appear on every other.
    /// Tokens themselves stay in the Keychain and never leave the device.
    static let iCloudAccountsKey = "accounts"

    func saveSetting<T>(_ value: T, forKey key: String) {
        UserDefaults.standard.set(value, forKey: key)
        guard iCloudSyncEnabled else { return }
        iCloudStore.set(value, forKey: key)
        iCloudStore.synchronize()
    }

    func saveLocalSetting<T>(_ value: T, forKey key: String) {
        UserDefaults.standard.set(value, forKey: key)
    }

    /// Called after account persistence. Mirrors the saved JSON blob to
    /// iCloud when sync is enabled so other devices pick up the new list.
    func syncAccountsToiCloudIfEnabled(encodedAccounts data: Data) {
        guard iCloudSyncEnabled else { return }
        iCloudStore.set(data, forKey: Self.iCloudAccountsKey)
        iCloudStore.synchronize()
    }

    /// Copies every synced key from iCloud into UserDefaults, one-way, at
    /// launch. Called from init (gated on `iCloudSyncEnabled`) so a fresh
    /// install on a second device picks up the user's prior settings.
    ///
    /// Belt-and-suspenders: refuse to overwrite a non-empty local accounts
    /// list with an empty remote blob. Even with the caller gated on the
    /// toggle, this protects against the historical wipe pattern where a
    /// stale empty blob in iCloud KVS would silently clear every account
    /// after one restart.
    func syncAllSettingsFromiCloudToUserDefaults() {
        for key in Self.iCloudPreferenceKeys + [Self.iCloudAccountsKey] {
            guard let value = iCloudStore.object(forKey: key) else { continue }

            if key == Self.iCloudAccountsKey, emptyAccountsBlobWouldWipeLocal(remote: value) {
                AppLogger.info("Skipping iCloud accounts sync — remote blob is empty, local has entries", log: AppLogger.settings)
                continue
            }

            UserDefaults.standard.set(value, forKey: key)
        }
    }

    /// Returns true when `remote` is an encoded empty `[LinearAccount]` and
    /// the local UserDefaults copy decodes to a non-empty list. Only in that
    /// case do we refuse the overwrite — any other shape (nil, malformed,
    /// non-empty remote) falls through to normal sync semantics.
    private func emptyAccountsBlobWouldWipeLocal(remote: Any) -> Bool {
        guard let remoteData = remote as? Data,
              let remoteAccounts = try? JSONDecoder().decode([LinearAccount].self, from: remoteData),
              remoteAccounts.isEmpty else {
            return false
        }
        guard let localData = UserDefaults.standard.data(forKey: Self.iCloudAccountsKey),
              let localAccounts = try? JSONDecoder().decode([LinearAccount].self, from: localData),
              !localAccounts.isEmpty else {
            return false
        }
        return true
    }

    func setupiCloudSync() {
        NotificationCenter.default.removeObserver(
            self,
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: iCloudStore
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(iCloudStoreDidChange),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: iCloudStore
        )
        iCloudStore.synchronize()
    }

    /// Removes the iCloud KVS observer. Called from applicationWillTerminate
    /// so the observer registration doesn't leak.
    func teardown() {
        NotificationCenter.default.removeObserver(
            self,
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: iCloudStore
        )
    }

    @objc func iCloudStoreDidChange(_ notification: Notification) {
        guard iCloudSyncEnabled else { return }

        guard let userInfo = notification.userInfo,
              let keys = userInfo[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String] else {
            return
        }

        for key in keys {
            if let value = iCloudStore.object(forKey: key) {
                UserDefaults.standard.set(value, forKey: key)
            }
        }

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.applyIncomingKeys(keys)
        }
    }

    /// Dispatches incoming key changes to the published properties that
    /// represent them. Kept separate from the observer so we can unit-test
    /// it in isolation.
    private func applyIncomingKeys(_ keys: [String]) {
        if keys.contains("refreshInterval") {
            let raw = UserDefaults.standard.string(forKey: "refreshInterval") ?? RefreshInterval.fifteenMinutes.rawValue
            refreshInterval = RefreshInterval(rawValue: raw) ?? .fifteenMinutes
        }
        if keys.contains("launchAtLogin") {
            launchAtLogin = UserDefaults.standard.bool(forKey: "launchAtLogin")
        }
        if keys.contains("defaultTab") {
            let raw = UserDefaults.standard.string(forKey: "defaultTab") ?? DefaultTab.inbox.rawValue
            defaultTab = DefaultTab(rawValue: raw) ?? .inbox
        }
        if keys.contains("showCompletedItems") {
            showCompletedItems = UserDefaults.standard.bool(forKey: "showCompletedItems")
        }
        if keys.contains("showCanceledItems") {
            showCanceledItems = UserDefaults.standard.bool(forKey: "showCanceledItems")
        }
        if keys.contains("sortOrder") {
            let raw = UserDefaults.standard.string(forKey: "sortOrder") ?? SortOrder.updatedNewest.rawValue
            sortOrder = SortOrder(rawValue: raw) ?? .updatedNewest
        }
        if keys.contains("demoModeEnabled") {
            demoModeEnabled = UserDefaults.standard.bool(forKey: "demoModeEnabled")
        }
        if keys.contains(Self.iCloudAccountsKey),
           let data = UserDefaults.standard.data(forKey: Self.iCloudAccountsKey),
           let decoded = try? JSONDecoder().decode([LinearAccount].self, from: data) {
            mergeRemoteAccounts(decoded)
        }
    }

    /// Merges accounts coming in from iCloud with what's on this device.
    /// Preserves the local `authStatus` because tokens are device-local —
    /// an account synced from another machine starts as `needsAuth` here
    /// until the user signs in. The remote is the source of truth for
    /// everything else (display name, color, enabled flag).
    private func mergeRemoteAccounts(_ remote: [LinearAccount]) {
        var merged: [LinearAccount] = []
        for remoteAccount in remote {
            if let local = accounts.first(where: { $0.email == remoteAccount.email }),
               KeychainService.shared.retrieveAccessToken(forAccount: local.email) != nil {
                var next = remoteAccount
                next.authStatus = local.authStatus
                merged.append(next)
            } else {
                var fresh = remoteAccount
                fresh.authStatus = .needsAuth
                merged.append(fresh)
            }
        }
        accounts = merged
    }
}
