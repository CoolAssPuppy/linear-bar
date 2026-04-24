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
    /// assignee chip. `team { id }` is the only team field any view
    /// reads — `name`/`key`/`icon` come from the Teams store. The
    /// `project` ref isn't rendered anywhere on issue rows today; the
    /// Swift model's `Issue.project` stays optional for forward-compat.
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
    team { id }
    """

    /// Fields selected on `Project` for Recent / Search surfaces.
    /// `state` drives the Show-completed/canceled filter; `lead { name }`
    /// drives the trailing initials column. `icon`, `progress`, and
    /// `targetDate` have no readers today.
    static let projectFields = """
    id
    name
    url
    updatedAt
    state
    lead { name }
    """

    /// Fields selected on `Initiative` for Recent / Search surfaces.
    /// `status` drives the Show-completed/canceled filter.
    static let initiativeFields = """
    id
    name
    url
    updatedAt
    status
    """
}
