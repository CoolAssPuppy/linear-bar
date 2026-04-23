import Foundation

/// Short, compact relative timestamps used throughout the popover
/// (`3m`, `22h`, `2d`). Matches the visual density of the Paper designs —
/// the menu bar has no room for "3 minutes ago" prose.
enum RelativeTimeFormatter {
    static func shortLabel(for date: Date, reference: Date = Date()) -> String {
        let seconds = Int(reference.timeIntervalSince(date))
        if seconds < 60 {
            return seconds <= 0 ? "now" : "\(seconds)s"
        }
        if seconds < 3600 {
            return "\(seconds / 60)m"
        }
        if seconds < 86_400 {
            return "\(seconds / 3600)h"
        }
        let days = seconds / 86_400
        if days < 7 {
            return "\(days)d"
        }
        if days < 30 {
            return "\(days / 7)w"
        }
        if days < 365 {
            return "\(days / 30)mo"
        }
        return "\(days / 365)y"
    }
}
