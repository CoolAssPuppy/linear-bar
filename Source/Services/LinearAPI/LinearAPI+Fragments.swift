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
    /// (Inbox, Mine, Recent, Search). Covers identifier rendering,
    /// state circle, due-date label, row click target, sort keys, and
    /// assignee chip.
    ///
    /// `team { id name key icon }`: only `team.id` is consumed by views,
    /// but `Team.name` and `Team.key` are non-optional on the Swift
    /// model — requesting just `{ id }` makes every issue fail to
    /// decode (`JSONDecoder` throws on the missing keys, the client's
    /// `try?` swallows it, and the caller sees the generic "Invalid
    /// response" error). Keep the full selection until the Team model
    /// is refactored to make those fields optional.
    ///
    /// `project` was previously included with id/name/icon but no view
    /// consumes `Issue.project`; `ProjectReference` is optional on the
    /// model so omitting the whole selection is safe.
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
    """

    /// Fields selected on `Project` for Recent / Search surfaces.
    /// `state` drives the Show-completed/canceled filter; `lead { name }`
    /// drives the trailing initials column. `teams { nodes { id } }`
    /// powers team-scope filtering — a project surfaces under a team
    /// scope only if it belongs to that team. `icon`, `progress`, and
    /// `targetDate` have no readers today.
    static let projectFields = """
    id
    name
    url
    updatedAt
    state
    lead { name }
    teams(first: 50) { nodes { id } }
    """

    /// Fields selected on `Initiative` for Recent / Search surfaces.
    /// `status` drives the Show-completed/canceled filter.
    /// `projects { nodes { teams { nodes { id } } } }` lets us derive the
    /// set of teams an initiative spans (initiatives don't own teams
    /// directly in Linear) so team-scope filtering can include or hide
    /// the initiative based on the active scope.
    static let initiativeFields = """
    id
    name
    url
    updatedAt
    status
    projects(first: 50) { nodes { teams(first: 50) { nodes { id } } } }
    """
}
