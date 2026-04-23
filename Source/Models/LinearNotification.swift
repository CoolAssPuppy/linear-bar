import Foundation

/// A single entry from Linear's notifications feed. The GraphQL schema uses
/// polymorphic subtypes (IssueNotification, ProjectNotification, etc.); this
/// struct flattens them into optional fields because every subtype shares the
/// common `id`/`type`/`createdAt`/`actor` surface. Exactly one of the target
/// fields (issue / project / document) will be set, matching the subtype.
struct LinearNotification: Identifiable, Codable, Hashable {
    let id: String
    /// Discriminator. Linear emits values like `issueAssignedToYou`,
    /// `issueMention`, `projectUpdateCreated`, `documentMention`, etc. Used
    /// to pick the reason phrase the row shows.
    let type: String
    let createdAt: Date?
    let readAt: Date?
    let snoozedUntilAt: Date?

    let actor: NotificationActor?

    // Polymorphic targets. Exactly one is non-nil in practice.
    let issue: NotificationIssueTarget?
    let project: NotificationProjectTarget?
    let document: NotificationDocumentTarget?

    /// Short verb phrase describing the notification reason. Rendered to the
    /// right of the actor's name in the inbox row.
    var reasonPhrase: String {
        switch type {
        case "issueAssignedToYou":            return "assigned to you"
        case "issueUnassignedFromYou":        return "unassigned from you"
        case "issueMention":                  return "mentioned you"
        case "issueCommentMention":           return "mentioned you"
        case "issueNewComment":               return "commented on"
        case "issueStatusChanged":            return "changed status on"
        case "issuePriorityUrgent":           return "marked urgent"
        case "issueDue":                      return "is due on"
        case "issueReviewRequested":          return "requested review on"
        case "issueReactionCreated":          return "reacted to"
        case "issueSlaBreached":              return "SLA breached on"
        case "issueSlaHighRisk":              return "SLA at risk on"
        case "projectUpdateCreated":          return "posted an update on"
        case "projectUpdatePrompt":           return "update requested for"
        case "projectUpdateReminder":         return "update reminder for"
        case "projectMention":                return "mentioned you in"
        case "documentMention":               return "mentioned you in"
        case "documentCommentMention":        return "mentioned you in"
        case "triageResponsibilityIssueAddedToTriage":
                                              return "new triage item on"
        default:                              return "updated"
        }
    }

    /// True when the notification represents a breach or at-risk SLA. Drives
    /// red styling on the row and the urgent state on the menu bar icon.
    var isUrgent: Bool {
        switch type {
        case "issueSlaBreached", "issueSlaHighRisk", "issuePriorityUrgent":
            return true
        default:
            return false
        }
    }

    /// URL to open in Linear when the row is clicked. Falls back to the target
    /// object's URL if the notification itself doesn't expose one.
    var targetURL: URL? {
        if let urlString = issue?.url ?? project?.url ?? document?.url {
            return URL(string: urlString)
        }
        return nil
    }
}

struct NotificationActor: Codable, Hashable {
    let id: String?
    let name: String?
    let displayName: String?
    let avatarUrl: String?

    var label: String {
        displayName ?? name ?? "Linear"
    }

    var initials: String {
        let source = displayName ?? name ?? "Linear"
        let components = source.split(separator: " ").prefix(2)
        let letters = components.compactMap { $0.first }.map { String($0) }
        return letters.joined().uppercased()
    }
}

struct NotificationIssueTarget: Codable, Hashable {
    let id: String
    let identifier: String
    let title: String
    let url: String
    let state: IssueState?
    let priority: Int?
    let priorityLabel: String?
    let team: NotificationTeamRef?
}

struct NotificationProjectTarget: Codable, Hashable {
    let id: String
    let name: String
    let url: String
    let icon: String?
    let color: String?
}

struct NotificationDocumentTarget: Codable, Hashable {
    let id: String
    let title: String
    let url: String
    let icon: String?
    let color: String?
}

struct NotificationTeamRef: Codable, Hashable {
    let id: String
    let name: String
    let key: String
}
