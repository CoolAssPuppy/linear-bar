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
    let archivedAt: Date?
    let snoozedUntilAt: Date?

    let actor: NotificationActor?

    // Polymorphic targets. Exactly one is non-nil in practice.
    let issue: NotificationIssueTarget?
    let project: NotificationProjectTarget?
    let document: NotificationDocumentTarget?

    // Linear supplies these presentation fields on the shared Notification
    // interface, including notification types without a queryable target object.
    let title: String?
    let subtitle: String?
    let url: String?

    /// Linear groups inbox rows that share this key. Missing on older fixtures.
    let groupingKey: String?
    let groupingPriority: Double?

    init(
        id: String,
        type: String,
        createdAt: Date?,
        readAt: Date?,
        archivedAt: Date?,
        snoozedUntilAt: Date?,
        actor: NotificationActor?,
        issue: NotificationIssueTarget?,
        project: NotificationProjectTarget?,
        document: NotificationDocumentTarget?,
        title: String? = nil,
        subtitle: String? = nil,
        url: String? = nil,
        groupingKey: String? = nil,
        groupingPriority: Double? = nil
    ) {
        self.id = id
        self.type = type
        self.createdAt = createdAt
        self.readAt = readAt
        self.archivedAt = archivedAt
        self.snoozedUntilAt = snoozedUntilAt
        self.actor = actor
        self.issue = issue
        self.project = project
        self.document = document
        self.title = title
        self.subtitle = subtitle
        self.url = url
        self.groupingKey = groupingKey
        self.groupingPriority = groupingPriority
    }

    var presentationTitle: String {
        nonEmpty(title)
            ?? nonEmpty(issue?.title)
            ?? nonEmpty(project?.name)
            ?? nonEmpty(document?.title)
            ?? "Linear notification"
    }

    var presentationSubtitle: String {
        nonEmpty(subtitle)
            ?? "\(actor?.label ?? "Linear") \(reasonPhrase)"
    }

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
        if let urlString = url ?? issue?.url ?? project?.url ?? document?.url {
            return SafeExternalURL.linearURL(from: urlString)
        }
        return nil
    }

    private func nonEmpty(_ value: String?) -> String? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty else {
            return nil
        }
        return value
    }
}

struct NotificationActor: Codable, Hashable {
    let id: String?
    let name: String?
    let displayName: String?
    let avatarUrl: String?

    var label: String { displayName ?? name ?? "Linear" }
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
