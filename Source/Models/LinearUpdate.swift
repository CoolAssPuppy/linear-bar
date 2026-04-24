import Foundation

/// A single project status update from Linear's Pulse feed. Combines
/// the authoring user, the target project, the `health` classification
/// the author picked (`onTrack` / `atRisk` / `offTrack`), and the free
/// body text. Linear's web Pulse shows a feed of these across the
/// workspace.
struct LinearProjectUpdate: Identifiable, Codable, Hashable {
    let id: String
    let body: String
    let createdAt: Date?
    /// Raw string from Linear's `ProjectUpdateHealthType` enum — values
    /// observed in production: `onTrack`, `atRisk`, `offTrack`. Left as
    /// String so unknown values decode instead of erroring.
    let health: String?
    let user: UpdateActor?
    let project: UpdateProjectRef?
}

struct UpdateActor: Codable, Hashable {
    let id: String?
    let name: String?
    let displayName: String?
    let avatarUrl: String?

    var label: String { displayName ?? name ?? "Someone" }
}

struct UpdateProjectRef: Codable, Hashable {
    let id: String
    let name: String
    let url: String
    let color: String?
    let icon: String?
}

/// Typed view over the raw `health` string. Unknown / nil values
/// surface as `.unknown`, which the row renders with a neutral chip
/// rather than hiding.
enum ProjectUpdateHealth: Hashable {
    case onTrack
    case atRisk
    case offTrack
    case unknown(String?)

    init(rawValue: String?) {
        switch rawValue {
        case "onTrack":  self = .onTrack
        case "atRisk":   self = .atRisk
        case "offTrack": self = .offTrack
        default:         self = .unknown(rawValue)
        }
    }

    var label: String {
        switch self {
        case .onTrack:            return "On track"
        case .atRisk:             return "At risk"
        case .offTrack:           return "Off track"
        case .unknown(let raw):   return raw?.capitalized ?? "Update"
        }
    }
}
