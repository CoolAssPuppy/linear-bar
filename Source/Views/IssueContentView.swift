import SwiftUI

struct IssueContentView: View {
    let issue: Issue

    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(issue.identifier)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(theme.foreground)

            Text(issue.title)
                .font(.system(size: 12))
                .foregroundStyle(theme.foregroundSoft)
                .lineLimit(1)

            if let description = issue.description, !description.isEmpty {
                Text(description)
                    .font(.system(size: 11))
                    .foregroundStyle(theme.muted)
                    .lineLimit(2)
            }

            if hasMetadata {
                metadataBadges
            }

            statusRow
        }
    }

    private var hasMetadata: Bool {
        issue.dueDate != nil || issue.project != nil || (issue.labels?.nodes.isEmpty == false)
    }

    private var metadataBadges: some View {
        HStack(spacing: 6) {
            if let dueDate = issue.dueDate {
                DueDateBadge(dueDate: dueDate, isOverdue: issue.isOverdue)
            }

            if let project = issue.project {
                ProjectBadge(project: project)
            }

            if let labels = issue.labels?.nodes, !labels.isEmpty {
                ForEach(labels.prefix(3)) { label in
                    LabelBadge(label: label)
                }
                if labels.count > 3 {
                    Text("+\(labels.count - 3)")
                        .font(.system(size: 10))
                        .foregroundStyle(theme.muted)
                }
            }
        }
    }

    private var statusRow: some View {
        HStack(spacing: 6) {
            if let state = issue.state {
                Text(state.name)
                    .font(.system(size: 10))
                    .foregroundStyle(theme.muted)
            }

            if let assignee = issue.assignee {
                Text("\u{2022}")
                    .foregroundStyle(theme.dim)
                Text(assignee.name)
                    .font(.system(size: 10))
                    .foregroundStyle(theme.muted)
            }
        }
    }
}
