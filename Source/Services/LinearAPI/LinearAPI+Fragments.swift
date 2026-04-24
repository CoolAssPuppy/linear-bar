import Foundation

/// Reusable GraphQL field selections for Linear queries. Kept as Swift
/// string constants and interpolated into query bodies — simpler than
/// wire-level `fragment … on Issue { … }` declarations and avoids the
/// variable-scope rules fragments impose.
///
/// Policy: every selection below is the *minimum* set consumed by the
/// popover/account UI. Adding a field here pays a per-request bandwidth
/// cost on every user every refresh — only add when a new UI surface
/// actually reads it. Fields that live on the Swift model but aren't
/// read by any view should be removed from the model too.
enum LinearGQL {

    /// Fields selected on `Issue` for every list/compact surface
    /// (Inbox, Mine, Recent, Search, Team, Cycle at-risk). Covers
    /// identifier rendering, state circle, due-date label, row click
    /// target, sort keys, and assignee chip.
    static let issueCompactFields = """
    id
    identifier
    title
    url
    createdAt
    updatedAt
    dueDate
    state { name type }
    assignee { name }
    team { id name key icon }
    project { id name icon }
    """

    /// Cycle-issue fields. Same shape as issueCompactFields minus the
    /// team/project refs (cycle is team-scoped, project isn't rendered
    /// in the Pulse at-risk row). `slaBreachesAt` is intentionally
    /// omitted — the current field has caused 400s on some workspaces
    /// historically and the Swift-model fallback (`riskReason`'s SLA
    /// branch returns nil when absent) degrades gracefully without it.
    static let cycleIssueFields = """
    id
    identifier
    title
    url
    updatedAt
    dueDate
    state { name type }
    assignee { name }
    """

    /// Fields selected on `Project` for Recent / Search surfaces.
    static let projectFields = """
    id
    name
    url
    createdAt
    updatedAt
    state
    progress
    icon
    lead { name }
    targetDate
    """

    /// Fields selected on `Initiative` for Recent / Search surfaces.
    static let initiativeFields = """
    id
    name
    url
    createdAt
    updatedAt
    icon
    status
    targetDate
    """
}
