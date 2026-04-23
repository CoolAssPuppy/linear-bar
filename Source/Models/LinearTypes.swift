import Foundation

/// A Linear artifact that renders uniformly in the popover: issues,
/// projects, and initiatives. The popover's Recent tab consumes the
/// protocol through `RecentArtifact`.
protocol LinearItem: Identifiable, Hashable {
    var id: String { get }
    var title: String { get }
    var url: String { get }
    var createdAt: Date? { get }
    var updatedAt: Date? { get }
    var itemType: LinearItemType { get }
}

enum LinearItemType: String {
    case issue
    case project
    case initiative
}

// MARK: - Issue

struct Issue: LinearItem, Codable {
    let id: String
    let identifier: String
    let title: String
    let description: String?
    let url: String
    let createdAt: Date?
    let updatedAt: Date?
    /// ISO 8601 date string (`YYYY-MM-DD`). Absent when the issue has no due date.
    let dueDate: String?
    let state: IssueState?
    let priority: Int?
    let priorityLabel: String?
    let assignee: User?
    let team: Team?
    let labels: LabelConnection?
    let project: ProjectReference?
    let parent: IssueReference?

    var itemType: LinearItemType { .issue }

    var isOverdue: Bool {
        guard let dueDate else { return false }
        guard let date = DateParsing.startOfDay(fromISODate: dueDate) else { return false }
        return date < Date()
    }
}

/// State on an issue. `type` carries the Linear state classification
/// (`triage`, `backlog`, `unstarted`, `started`, `completed`, `canceled`)
/// — decoded on demand via `kind` so views don't hand-switch strings.
struct IssueState: Codable, Hashable {
    let name: String
    let type: String
}

/// Typed view of the six canonical Linear issue state classifications.
enum IssueStateType: String {
    case triage
    case backlog
    case unstarted
    case started
    case completed
    case canceled
}

extension IssueState {
    var kind: IssueStateType? { IssueStateType(rawValue: type) }

    /// True when the issue is neither completed nor canceled.
    var isOpen: Bool {
        switch kind {
        case .completed, .canceled: return false
        default:                    return true
        }
    }
}

// MARK: - Issue Label

struct IssueLabel: Codable, Hashable, Identifiable {
    let id: String
    let name: String
    /// Linear hex color (`#RRGGBB`).
    let color: String
}

struct LabelConnection: Codable, Hashable {
    let nodes: [IssueLabel]
}

// MARK: - References

/// Lightweight project record embedded on `Issue.project`.
struct ProjectReference: Codable, Hashable {
    let id: String
    let name: String
    let icon: String?
}

/// Lightweight issue record embedded on `Issue.parent`.
struct IssueReference: Codable, Hashable {
    let id: String
    let identifier: String
    let title: String
}

// MARK: - Project

struct Project: LinearItem, Codable {
    let id: String
    let name: String
    let description: String?
    let url: String
    let createdAt: Date?
    let updatedAt: Date?
    /// Linear's project state (`planned`, `started`, `paused`, `completed`, `canceled`).
    let state: String
    let progress: Double?
    let icon: String?
    let lead: User?
    /// ISO 8601 date string (`YYYY-MM-DD`).
    let targetDate: String?

    var title: String { name }
    var itemType: LinearItemType { .project }

    var isOverdue: Bool {
        guard let targetDate else { return false }
        guard let date = DateParsing.startOfDay(fromISODate: targetDate) else { return false }
        return date < Date()
    }
}

// MARK: - Initiative

struct Initiative: LinearItem, Codable {
    let id: String
    let name: String
    let description: String?
    let url: String
    let createdAt: Date?
    let updatedAt: Date?
    let progress: Double?
    let icon: String?
    /// Linear's initiative status (`planned`, `active`, `completed`).
    let status: String?
    /// ISO 8601 date string (`YYYY-MM-DD`).
    let targetDate: String?

    var title: String { name }
    var itemType: LinearItemType { .initiative }

    var isOverdue: Bool {
        guard let targetDate else { return false }
        guard let date = DateParsing.startOfDay(fromISODate: targetDate) else { return false }
        return date < Date()
    }
}

// MARK: - Team

struct Team: Codable, Hashable, Identifiable {
    let id: String
    let name: String
    let key: String
    let icon: String?

    var displayName: String { "\(name) (\(key))" }
}

// MARK: - User

struct User: Codable, Hashable {
    let name: String
}

// MARK: - Viewer

struct Viewer: Codable {
    let id: String
    let name: String
    let email: String
    let organization: ViewerOrganization?
}

struct ViewerOrganization: Codable {
    let id: String
    let name: String
    /// Organization slug used in Linear URLs.
    let urlKey: String
}

// MARK: - GraphQL envelope

struct GraphQLResponse<T: Decodable>: Decodable {
    let data: T?
    let errors: [GraphQLError]?
}

struct GraphQLError: Decodable {
    let message: String
}

// MARK: - Shared date parsing

/// Shared ISO-8601 date-only parser. `Issue.isOverdue`, `Project.isOverdue`,
/// and `Initiative.isOverdue` all call this — allocating a fresh
/// `ISO8601DateFormatter` per access was measurable.
enum DateParsing {
    static func startOfDay(fromISODate date: String) -> Date? {
        isoFormatter.date(from: date + "T00:00:00Z")
    }

    private static let isoFormatter = ISO8601DateFormatter()
}
