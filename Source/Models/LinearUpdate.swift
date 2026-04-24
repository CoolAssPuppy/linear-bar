import Foundation

/// A single entry in Linear's Pulse feed. Project updates and initiative
/// updates share the same header / body / author shape on the wire, so
/// we flatten them into one struct with optional `project` and
/// `initiative` targets — exactly one is non-nil in practice. The row
/// renderer picks which header to show based on which target was
/// decoded.
struct LinearPulseUpdate: Identifiable, Codable, Hashable {
    let id: String
    let body: String
    let createdAt: Date?
    /// Raw string from Linear's `ProjectUpdateHealthType` enum (values
    /// observed: `onTrack`, `atRisk`, `offTrack`). Always nil on
    /// initiative updates — initiatives don't carry a health
    /// classification. Kept as String so unknown values decode.
    let health: String?
    let user: UpdateActor?
    let project: UpdateProjectRef?
    let initiative: UpdateInitiativeRef?
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
    /// Teams the project belongs to. Optional to tolerate older Linear
    /// workspaces whose `Project.teams` connection was renamed, and used
    /// only when the Pulse scope filter is "My Teams" — we intersect
    /// these with the viewer's team memberships.
    let teams: UpdateProjectTeamsRef?
}

struct UpdateProjectTeamsRef: Codable, Hashable {
    struct Node: Codable, Hashable { let id: String }
    let nodes: [Node]
}

struct UpdateInitiativeRef: Codable, Hashable {
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
