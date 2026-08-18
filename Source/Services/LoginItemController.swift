import Foundation
import Combine
import ServiceManagement

@MainActor
protocol LoginItemManaging: AnyObject {
    var isEnabled: Bool { get }
    func setEnabled(_ isEnabled: Bool) throws
}

@MainActor
final class SystemLoginItemManager: LoginItemManaging {
    var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    func setEnabled(_ isEnabled: Bool) throws {
        if isEnabled {
            if SMAppService.mainApp.status != .enabled {
                try SMAppService.mainApp.register()
            }
        } else if SMAppService.mainApp.status != .notRegistered {
            try SMAppService.mainApp.unregister()
        }
    }
}

@MainActor
final class LoginItemController: ObservableObject {
    @Published private(set) var isEnabled: Bool
    @Published private(set) var errorMessage: String?

    private let manager: LoginItemManaging

    init() {
        let manager = SystemLoginItemManager()
        self.manager = manager
        self.isEnabled = manager.isEnabled
    }

    init(manager: LoginItemManaging) {
        self.manager = manager
        self.isEnabled = manager.isEnabled
    }

    func setEnabled(_ isEnabled: Bool) {
        do {
            try manager.setEnabled(isEnabled)
            self.isEnabled = manager.isEnabled
            errorMessage = self.isEnabled == isEnabled
                ? nil
                : "macOS requires approval in System Settings before this app can open at login."
        } catch {
            self.isEnabled = manager.isEnabled
            errorMessage = "Could not update Launch at Login. Please try again."
            AppLogger.error("Failed to update login item", log: AppLogger.settings, error: error)
        }
    }

    func clearError() {
        errorMessage = nil
    }

    static func migrateLegacyPreference() {
        migrateLegacyPreference(defaults: .standard, manager: SystemLoginItemManager())
    }

    static func migrateLegacyPreference(defaults: UserDefaults, manager: LoginItemManaging) {
        guard defaults.object(forKey: "launchAtLogin") != nil else { return }

        let wasEnabled = defaults.bool(forKey: "launchAtLogin")
        do {
            if wasEnabled && !manager.isEnabled {
                try manager.setEnabled(true)
            }
            defaults.removeObject(forKey: "launchAtLogin")
        } catch {
            AppLogger.error("Failed to migrate the former Launch at Login preference", log: AppLogger.settings, error: error)
        }
    }
}
