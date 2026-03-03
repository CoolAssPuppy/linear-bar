import SwiftUI

struct IssueContentView: View {
    let issue: Issue

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(issue.identifier)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary)

            Text(issue.title)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .lineLimit(1)

            if let description = issue.description, !description.isEmpty {
                Text(description)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
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
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var statusRow: some View {
        HStack(spacing: 6) {
            if let state = issue.state {
                Text(state.name)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }

            if let assignee = issue.assignee {
                Text("\u{2022}")
                    .foregroundColor(.secondary)
                Text(assignee.name)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
    }
}
