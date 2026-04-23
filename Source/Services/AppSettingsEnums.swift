import Foundation

// MARK: - View Mode

enum ViewMode: String, CaseIterable, Identifiable {
    case createdByMe = "Created by Me"
    case assignedToMe = "Assigned to Me"
    case teamItems = "Team"

    var id: String { rawValue }
}

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
    case favorites = "Favorites"
    case recent = "Recent"
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
    /// Mirrors mail-notifier's `.openSettingsDrawer` mechanism.
    static let openSettingsDrawer = Notification.Name("openSettingsDrawer")

    /// Posted when the user has selected an account from the sidebar or
    /// elsewhere. The object is the `LinearAccount` that should be shown.
    static let accountSelected = Notification.Name("accountSelected")
}
