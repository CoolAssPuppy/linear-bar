import Foundation

// MARK: - Linear Item Protocol

protocol LinearItem: Identifiable, Hashable {
    var id: String { get }
    var title: String { get }
    var url: String { get }
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
    let url: String
    let updatedAt: Date?
    let state: IssueState?
    let priority: Int?
    let priorityLabel: String?
    let assignee: User?
    let team: Team?

    var itemType: LinearItemType { .issue }

    var displayIdentifier: String {
        identifier
    }

    var stateColor: String {
        state?.color ?? "#6B7280"
    }
}

struct IssueState: Codable, Hashable {
    let name: String
    let type: String // "unstarted", "started", "completed", "canceled"

    var color: String {
        switch type {
        case "completed":
            return "#5E6AD2" // Linear purple
        case "started":
            return "#F59E0B" // orange
        case "canceled":
            return "#6B7280" // gray
        default:
            return "#94A3B8" // slate
        }
    }
}

// MARK: - Project

struct Project: LinearItem, Codable {
    let id: String
    let name: String
    let url: String
    let updatedAt: Date?
    let state: String
    let progress: Double?
    let icon: String?
    let lead: User?

    var title: String { name }
    var itemType: LinearItemType { .project }

    var stateColor: String {
        switch state.lowercased() {
        case "completed":
            return "#5E6AD2" // Linear purple
        case "started", "in progress":
            return "#F59E0B" // orange/yellow
        case "canceled":
            return "#6B7280" // gray
        default:
            return "#94A3B8" // slate
        }
    }
}

// MARK: - Initiative

struct Initiative: LinearItem, Codable {
    let id: String
    let name: String
    let url: String
    let updatedAt: Date?
    let progress: Double?
    let icon: String?
    let status: String? // "planned", "active", "completed"

    var title: String { name }
    var itemType: LinearItemType { .initiative }
}

// MARK: - Team

struct Team: Codable, Hashable, Identifiable {
    let id: String
    let name: String
    let key: String
    let icon: String?

    var displayName: String {
        "\(name) (\(key))"
    }
}

// MARK: - User

struct User: Codable, Hashable {
    let name: String
}

// MARK: - Favorite

struct Favorite: Codable, Identifiable {
    let id: String
    let type: String?
    let sortOrder: Double
    let folderName: String?
    let issue: Issue?
    let project: Project?
    let initiative: Initiative?
    let customView: FavoriteItem?
    let cycle: FavoriteItem?
    let label: FavoriteItem?
    let parent: FavoriteParent?
    let children: FavoriteChildren?

    struct FavoriteParent: Codable {
        let id: String
    }

    struct FavoriteChildren: Codable {
        struct ChildNode: Codable {
            let id: String
        }
        let nodes: [ChildNode]
    }

    var item: (any LinearItem)? {
        if let issue = issue {
            return issue
        } else if let project = project {
            return project
        } else if let initiative = initiative {
            return initiative
        }
        return nil
    }

    var displayName: String? {
        if let item = item {
            return item.title
        } else if let customView = customView {
            return customView.name
        } else if let cycle = cycle {
            return cycle.name
        } else if let label = label {
            return label.name
        }
        return folderName
    }
}

// MARK: - FavoriteItem (for roadmaps, views, cycles, labels, etc.)

struct FavoriteItem: Codable {
    let id: String
    let name: String
    let icon: String?
    let url: String?
    let color: String?
    let startsAt: String?
    let endsAt: String?
}

// MARK: - Viewer

struct Viewer: Codable {
    let id: String
    let name: String
    let email: String
}

// MARK: - GraphQL Responses

struct GraphQLResponse<T: Decodable>: Decodable {
    let data: T?
    let errors: [GraphQLError]?
}

struct GraphQLError: Decodable {
    let message: String
    let path: [String]?
    let extensions: [String: AnyCodable]?
}

// Helper to decode any JSON value
struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let arrayValue = try? container.decode([AnyCodable].self) {
            value = arrayValue.map { $0.value }
        } else if let dictValue = try? container.decode([String: AnyCodable].self) {
            value = dictValue.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let intValue = value as? Int {
            try container.encode(intValue)
        } else if let doubleValue = value as? Double {
            try container.encode(doubleValue)
        } else if let boolValue = value as? Bool {
            try container.encode(boolValue)
        } else if let stringValue = value as? String {
            try container.encode(stringValue)
        } else {
            try container.encodeNil()
        }
    }
}
