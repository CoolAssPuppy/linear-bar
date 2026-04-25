import SwiftUI

/// Single row used by the Recent tab. Accepts any of the three Linear
/// artifact types and routes the leading glyph accordingly — state circle
/// for issues, colored square for projects, outlined diamond for initiatives.
struct RecentArtifactRow: View {
    let item: RecentArtifact

    @Environment(\.theme) private var theme
    @State private var isHovered = false

    var body: some View {
        Button(action: openInLinear) {
            HStack(spacing: 10) {
                leadingGlyph
                    .frame(width: 14, alignment: .center)

                IssueIdentifierLabel(identifier: leadingLabel)
                RowCopyLinkButton(url: item.url, label: leadingLabel, isRowHovered: isHovered)

                Text(item.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(theme.foreground)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)

                trailing
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Rectangle().fill(isHovered ? theme.cardInset : Color.clear))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }

    @ViewBuilder
    private var leadingGlyph: some View {
        switch item {
        case .issue(let issue):
            IssueStateCircle(state: issue.state)
        case .project:
            ProjectGlyph(color: nil)
        case .initiative:
            InitiativeGlyph()
        }
    }

    private var leadingLabel: String {
        switch item {
        case .issue(let issue): return issue.identifier
        case .project:          return "PROJ"
        case .initiative:       return "INIT"
        }
    }

    private var trailing: some View {
        HStack(spacing: 5) {
            Text(actorInitials)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(theme.muted)
            Text(RelativeTimeFormatter.shortLabel(for: item.updatedAt ?? Date()))
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(theme.tertiary)
        }
        .fixedSize()
    }

    private var actorInitials: String {
        PersonName.initials(from: item.leadLabel)
    }

    private func openInLinear() {
        _ = SafeExternalURL.openLinearURL(from: item.url)
    }
}

/// Tagged union covering the three artifact types the Recent tab mixes.
enum RecentArtifact: Identifiable {
    case issue(Issue)
    case project(Project)
    case initiative(Initiative)

    var id: String {
        switch self {
        case .issue(let issue):           return "issue:\(issue.id)"
        case .project(let project):       return "project:\(project.id)"
        case .initiative(let initiative): return "initiative:\(initiative.id)"
        }
    }

    var title: String {
        switch self {
        case .issue(let issue):           return issue.title
        case .project(let project):       return project.name
        case .initiative(let initiative): return initiative.name
        }
    }

    var url: String {
        switch self {
        case .issue(let issue):           return issue.url
        case .project(let project):       return project.url
        case .initiative(let initiative): return initiative.url
        }
    }

    var updatedAt: Date? {
        switch self {
        case .issue(let issue):           return issue.updatedAt
        case .project(let project):       return project.updatedAt
        case .initiative(let initiative): return initiative.updatedAt
        }
    }

    /// Used for the trailing initials column. Issues surface their
    /// assignee; projects and initiatives surface their lead.
    var leadLabel: String? {
        switch self {
        case .issue(let issue):           return issue.assignee?.name
        case .project(let project):       return project.lead?.name
        case .initiative:                 return nil
        }
    }

    /// Team scoping. Issues carry a single team id; projects can span
    /// multiple teams; initiatives derive their teams from the projects
    /// they group. The artifact matches a scope if the scope's team id
    /// appears anywhere in that surface area.
    func matches(teamId: String) -> Bool {
        switch self {
        case .issue(let issue):           return issue.team?.id == teamId
        case .project(let project):       return project.teamIds.contains(teamId)
        case .initiative(let initiative): return initiative.teamIds.contains(teamId)
        }
    }
}
