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
    /// `document`, `cycle`, `customView`, `label`, `roadmap`,
    /// `predefinedView`, `projectTeam`. We only render issue/project
    /// today; the rest pass through with nil targets and get skipped.
    let type: String
    /// Optional folder name the viewer has organized this favorite
    /// into. Used later for grouping; safe to ignore today.
    let folderName: String?

    let issue: FavoriteIssueTarget?
    let project: FavoriteProjectTarget?
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
