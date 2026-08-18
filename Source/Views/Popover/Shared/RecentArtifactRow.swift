import SwiftUI

struct RecentArtifactRow: View {
    let item: RecentArtifact

    @Environment(\.theme) private var theme
    @State private var isHovered = false

    var body: some View {
        Button(action: openInLinear) {
            HStack(spacing: 10) {
                leadingGlyph.frame(width: 14, alignment: .center)
                IssueIdentifierLabel(identifier: leadingLabel)

                Text(item.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(theme.foreground)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let updatedAt = item.updatedAt {
                    Text(RelativeTimeFormatter.shortLabel(for: updatedAt))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(theme.tertiary)
                        .fixedSize()
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Rectangle().fill(isHovered ? theme.cardInset : Color.clear))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .contextMenu {
            Button("Copy link") { NSPasteboard.copyString(item.url) }
        }
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

    private func openInLinear() {
        _ = SafeExternalURL.openLinearURL(from: item.url)
    }
}

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

    func matches(teamId: String) -> Bool {
        switch self {
        case .issue(let issue):           return issue.team?.id == teamId
        case .project(let project):       return project.teamIds.contains(teamId)
        case .initiative(let initiative): return initiative.teamIds.contains(teamId)
        }
    }
}
