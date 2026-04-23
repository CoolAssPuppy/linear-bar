import Foundation

/// An active Linear cycle with its pre-computed scope history arrays and the
/// list of issues it contains. The Pulse tab renders one of these per team
/// the viewer is on.
struct LinearCycle: Codable, Hashable {
    let id: String
    let name: String?
    let number: Int
    let startsAt: Date
    let endsAt: Date
    /// 0...1 float Linear pre-computes. Displayed as the big percent number.
    let progress: Double

    /// Per-day parallel arrays indexed against `startsAt..endsAt`. Used to
    /// render the burndown sparkline and the scope-delta indicator. Linear
    /// ships these already aggregated — no folding required on the client.
    let scopeHistory: [Double]
    let completedScopeHistory: [Double]
    let inProgressScopeHistory: [Double]

    /// Issues belonging to this cycle that are still open (not completed and
    /// not canceled). The Pulse view ranks them client-side by risk signal.
    let issues: IssueCollection

    struct IssueCollection: Codable, Hashable {
        let nodes: [CycleIssue]
    }

    /// Days remaining until the cycle closes. Negative when the cycle has
    /// already ended (treated as zero for display).
    var daysLeft: Int {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: Date(), to: endsAt).day ?? 0
        return max(days, 0)
    }

    /// Human label for the pace indicator. Favors `Behind pace` when the
    /// completed fraction trails the elapsed fraction, `On pace` otherwise.
    /// Returns `Done` once the cycle has effectively completed.
    var paceLabel: String {
        if progress >= 0.999 { return "Done" }
        let elapsed = elapsedFraction
        if elapsed <= 0 { return "Starting" }
        return progress < elapsed - 0.05 ? "Behind pace" : "On pace"
    }

    /// Fraction of the cycle window that has elapsed. Used to compare against
    /// `progress` for the pace label.
    var elapsedFraction: Double {
        let total = endsAt.timeIntervalSince(startsAt)
        guard total > 0 else { return 0 }
        let elapsed = Date().timeIntervalSince(startsAt)
        return max(0, min(1, elapsed / total))
    }

    /// Scope growth between the start and end of the recorded window. Positive
    /// numbers mean scope crept up during the cycle. Used for the red `+12%`
    /// indicator on the cycle card.
    var scopeDeltaFraction: Double? {
        guard let first = scopeHistory.first, first > 0,
              let last = scopeHistory.last else {
            return nil
        }
        return (last - first) / first
    }
}

/// Lightweight issue record embedded in the cycle payload. Carries just what
/// the at-risk list needs to render and rank — full issue detail is never
/// required from this surface.
struct CycleIssue: Codable, Hashable, Identifiable {
    let id: String
    let identifier: String
    let title: String
    let url: String
    let updatedAt: Date?
    let dueDate: String?
    let priority: Int?
    let priorityLabel: String?
    let state: IssueState?
    let assignee: User?
    let slaBreachesAt: Date?

    /// Classifies why this issue is threatening the cycle. Used to label the
    /// row (`SLA 47m`, `Unassigned`, `Blocked`, etc.) and to sort the list.
    var riskReason: CycleRiskReason {
        if let slaBreachesAt = slaBreachesAt {
            let minutesLeft = Int(slaBreachesAt.timeIntervalSinceNow / 60)
            return .slaWarning(minutesLeft: minutesLeft)
        }
        if state?.type == "started" {
            if let updated = updatedAt, Date().timeIntervalSince(updated) > 3 * 24 * 60 * 60 {
                let days = Int(Date().timeIntervalSince(updated) / (24 * 60 * 60))
                return .stale(days: days)
            }
            return .inProgress
        }
        if assignee == nil {
            return .unassigned
        }
        return .pending
    }
}

/// Why a cycle issue is on the at-risk list. Ordered by display priority:
/// SLA first, then stale, then unassigned, then generic pending.
enum CycleRiskReason {
    case slaWarning(minutesLeft: Int)
    case stale(days: Int)
    case unassigned
    case inProgress
    case pending

    /// Ranks reasons for sorting the at-risk list. Lower is worse (shown first).
    var severity: Int {
        switch self {
        case .slaWarning: return 0
        case .stale:      return 1
        case .unassigned: return 2
        case .inProgress: return 3
        case .pending:    return 4
        }
    }

    var label: String {
        switch self {
        case .slaWarning(let minutes):
            if minutes <= 0 { return "SLA breached" }
            if minutes < 60 { return "SLA \(minutes)m" }
            let hours = minutes / 60
            return "SLA \(hours)h"
        case .stale(let days):
            return "Stale \(days)d"
        case .unassigned:
            return "Unassigned"
        case .inProgress:
            return "In progress"
        case .pending:
            return "Pending"
        }
    }

    /// True when the reason is hot enough to warrant red styling on the row.
    var isCritical: Bool {
        switch self {
        case .slaWarning, .stale: return true
        default:                  return false
        }
    }
}
