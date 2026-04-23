import Foundation

// MARK: - Refresh Interval

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

// MARK: - Default Tab

enum DefaultTab: String, CaseIterable, Identifiable {
    case inbox = "Inbox"
    case mine = "Mine"
    case recent = "Recent"
    case pulse = "Pulse"
    case search = "Search"

    var id: String { rawValue }
}

// MARK: - Sort Order

enum SortOrder: String, CaseIterable, Identifiable {
    case createdNewest = "Created Date, Newest First"
    case createdOldest = "Created Date, Oldest First"
    case updatedNewest = "Updated Date, Newest First"
    case updatedOldest = "Updated Date, Oldest First"
    case dueDate = "Due Date"

    var id: String { rawValue }
}

// MARK: - Notification Names

extension Notification.Name {
    static let accountsDidUpdate = Notification.Name("accountsDidUpdate")
    static let settingsRequested = Notification.Name("settingsRequested")
    static let refreshAllData = Notification.Name("refreshAllData")

    /// Posted to toggle the Settings drawer inside the main window.
    static let openSettingsDrawer = Notification.Name("openSettingsDrawer")

    /// Posted when the user wants to open the main window without the
    /// Settings drawer — specifically the popover bottom bar's macwindow
    /// button, which should just surface the accounts view.
    static let mainWindowRequested = Notification.Name("mainWindowRequested")

    /// Posted when the user has selected an account from the sidebar or
    /// elsewhere. The object is the `LinearAccount` that should be shown.
    static let accountSelected = Notification.Name("accountSelected")

    /// Posted when the user changes the team filter in any popover tab.
    /// Other tabs observe this to re-filter their open data.
    static let teamFilterChanged = Notification.Name("teamFilterChanged")
}
