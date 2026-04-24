import Foundation

/// Shared predicate that respects the `Show completed items` and
/// `Show canceled items` toggles in Settings. Lives as a free function so
/// every list view (Inbox, Mine, Recent, Pulse, Search) applies the same
/// rule — the toggles are a single source of truth.
@MainActor
enum ListFilter {
    static func keep(_ issue: Issue, settings: AppSettings = .shared) -> Bool {
        switch issue.state?.kind {
        case .completed: return settings.showCompletedItems
        case .canceled:  return settings.showCanceledItems
        default:         return true
        }
    }

    static func keep(_ project: Project, settings: AppSettings = .shared) -> Bool {
        switch project.state {
        case "completed": return settings.showCompletedItems
        case "canceled":  return settings.showCanceledItems
        default:          return true
        }
    }

    static func keep(_ initiative: Initiative, settings: AppSettings = .shared) -> Bool {
        switch initiative.status {
        case "completed"?: return settings.showCompletedItems
        case "canceled"?:  return settings.showCanceledItems
        default:           return true
        }
    }
}
