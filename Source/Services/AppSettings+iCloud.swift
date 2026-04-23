import Foundation

extension AppSettings {

    func saveSetting<T>(_ value: T, forKey key: String) {
        UserDefaults.standard.set(value, forKey: key)
        iCloudStore.set(value, forKey: key)
        iCloudStore.synchronize()
    }

    func saveLocalSetting<T>(_ value: T, forKey key: String) {
        UserDefaults.standard.set(value, forKey: key)
    }

    func syncAllSettingsFromiCloudToUserDefaults() {
        let settingsKeys = ["defaultViewMode", "refreshInterval", "launchAtLogin", "defaultTab", "showCompletedItems", "showCanceledItems", "sortOrder"]

        for key in settingsKeys {
            if let value = iCloudStore.object(forKey: key) {
                UserDefaults.standard.set(value, forKey: key)
            }
        }
    }

    func setupiCloudSync() {
        // Defensive: remove any existing registration before re-adding so that
        // repeated calls (hot-reload, reinitialisation) cannot stack observers.
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

    /// Removes the iCloud KVS observer. Must be called from
    /// `applicationWillTerminate` to avoid leaking the observer registration.
    func teardown() {
        NotificationCenter.default.removeObserver(
            self,
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: iCloudStore
        )
    }

    @objc func iCloudStoreDidChange(_ notification: Notification) {
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
                let tabRaw = UserDefaults.standard.string(forKey: "defaultTab") ?? DefaultTab.inbox.rawValue
                self.defaultTab = DefaultTab(rawValue: tabRaw) ?? .inbox
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
