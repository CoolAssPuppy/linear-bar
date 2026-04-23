import SwiftUI

struct ProjectContentView: View {
    let project: Project

    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(project.name)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(theme.foreground)
                .lineLimit(1)

            if let description = project.description, !description.isEmpty {
                Text(description)
                    .font(.system(size: 11))
                    .foregroundStyle(theme.muted)
                    .lineLimit(2)
            }

            if let targetDate = project.targetDate {
                HStack(spacing: 6) {
                    DueDateBadge(dueDate: targetDate, isOverdue: project.isOverdue)
                }
            }

            statusRow
        }
    }

    private var statusRow: some View {
        HStack(spacing: 6) {
            Text(normalizedState)
                .font(.system(size: 10))
                .foregroundStyle(theme.muted)

            if let progress = project.progress {
                Text("\u{2022}")
                    .foregroundStyle(theme.dim)
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 10))
                    .foregroundStyle(theme.muted)
            }

            if let lead = project.lead {
                Text("\u{2022}")
                    .foregroundStyle(theme.dim)
                Text(lead.name)
                    .font(.system(size: 10))
                    .foregroundStyle(theme.muted)
            }
        }
    }

    private var normalizedState: String {
        switch project.state.lowercased() {
        case "started": return "In Progress"
        case "backlog": return "Backlog"
        case "planned": return "Planned"
        case "paused": return "Paused"
        case "completed": return "Completed"
        case "canceled": return "Canceled"
        default: return project.state.capitalized
        }
    }
}
