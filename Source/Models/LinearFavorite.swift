import Foundation

/// A single entry from the viewer's Linear favorites list. Linear's
/// schema exposes `Favorite` as a polymorphic record with an optional
/// `issue`, `project`, `document`, `cycle`, etc. — we decode only the
/// subtypes the popover actually renders. Extra subtypes coming from
/// the server deserialize with all optional targets nil and are
/// filtered out at the view layer.
struct LinearFavorite: Identifiable, Codable, Hashable {
    let id: String
    /// Linear's discriminator. Values observed: `issue`, `project`,
    /// `customView`, `document`, `cycle`, `label`, `roadmap`,
    /// `predefinedView`, `projectTeam`, `folder`. We render issue,
    /// project, and customView; the rest pass through with nil targets
    /// and get skipped at the row level.
    let type: String
    /// Optional folder name the viewer has organized this favorite
    /// into. Used as a trailing chip on rows for grouping context.
    let folderName: String?

    let issue: FavoriteIssueTarget?
    let project: FavoriteProjectTarget?
    let customView: FavoriteCustomViewTarget?
}

struct FavoriteIssueTarget: Codable, Hashable {
    let id: String
    let identifier: String
    let title: String
    let url: String
    let state: IssueState?
    let team: Team?
}

struct FavoriteProjectTarget: Codable, Hashable {
    let id: String
    let name: String
    let url: String
    let icon: String?
    let color: String?
    let state: String?
    let progress: Double?
}

struct FavoriteCustomViewTarget: Codable, Hashable {
    let id: String
    let name: String
    /// Linear's `CustomView` type doesn't expose a `url` field in the
    /// GraphQL schema — selecting it returns a type error. FavesView
    /// synthesizes the URL at render time from the workspace slug and
    /// the view id.
    let icon: String?
    let color: String?
}
