import Foundation

/// Linear's inbox number: unread, not archived, not snoozed, one row per group.
enum InboxCount {
    static func unread(in notifications: [LinearNotification], now: Date = Date()) -> Int {
        inboxItems(in: notifications, now: now).count
    }

    static func inboxItems(in notifications: [LinearNotification], now: Date = Date()) -> [LinearNotification] {
        grouped(notifications.filter { isVisible($0, now: now) && $0.readAt == nil })
    }

    static func badge(total: Int, perAccount: [String: Int], currentEmail: String?) -> Int {
        if let currentEmail, let count = perAccount[currentEmail] {
            return count
        }
        return total
    }

    static func isVisible(_ notification: LinearNotification, now: Date = Date()) -> Bool {
        guard notification.archivedAt == nil else { return false }
        if let snoozedUntil = notification.snoozedUntilAt, snoozedUntil > now { return false }
        return true
    }

    private static func grouped(_ notifications: [LinearNotification]) -> [LinearNotification] {
        Dictionary(grouping: notifications, by: { $0.groupingKey ?? $0.id })
            .values
            .compactMap(representative)
            .sorted { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
    }

    private static func representative(in group: [LinearNotification]) -> LinearNotification? {
        group.max { lhs, rhs in
            let left = lhs.groupingPriority ?? 0
            let right = rhs.groupingPriority ?? 0
            if left != right { return left < right }
            return (lhs.createdAt ?? .distantPast) < (rhs.createdAt ?? .distantPast)
        }
    }
}
