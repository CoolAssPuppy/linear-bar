import SwiftUI

/// Reusable row component for displaying Linear items (issues, projects, initiatives)
struct ItemRow: View {
    let issue: Issue?
    let project: Project?
    let initiative: Initiative?
    let accountColor: String?

    @State private var isHovered = false

    init(issue: Issue, accountColor: String? = nil) {
        self.issue = issue
        self.project = nil
        self.initiative = nil
        self.accountColor = accountColor
    }

    init(project: Project, accountColor: String? = nil) {
        self.issue = nil
        self.project = project
        self.initiative = nil
        self.accountColor = accountColor
    }

    init(initiative: Initiative, accountColor: String? = nil) {
        self.issue = nil
        self.project = nil
        self.initiative = initiative
        self.accountColor = accountColor
    }

    var body: some View {
        Button(action: openInLinear) {
            HStack(spacing: 12) {
                if let color = accountColor {
                    Rectangle()
                        .fill(Color(hex: color))
                        .frame(width: 3)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        typeIcon

                        if let issue = issue {
                            IssueContentView(issue: issue)
                        } else if let project = project {
                            ProjectContentView(project: project)
                        } else if let initiative = initiative {
                            InitiativeContentView(initiative: initiative)
                        }

                        Spacer()

                        if isHovered {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(isHovered ? Color.accentColor.opacity(0.05) : Color.clear)
        .cornerRadius(6)
        .onHover { hovering in
            isHovered = hovering
        }
    }

    // MARK: - Type Icon

    private var typeIcon: some View {
        Group {
            if let issue = issue {
                IssueStatusIcon(issue: issue)
            } else if let project = project {
                ProjectStatusIcon(project: project)
            } else if let initiative = initiative {
                InitiativeStatusIcon(initiative: initiative)
            }
        }
        .font(.system(size: 16))
    }

    // MARK: - Actions

    private func openInLinear() {
        let urlString = issue?.url ?? project?.url ?? initiative?.url
        if let urlString = urlString, let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - Issue Status Icon

private struct IssueStatusIcon: View {
    let issue: Issue

    var body: some View {
        Group {
            switch issue.state?.name.lowercased() {
            case "triage":
                Image(systemName: "circle.dashed").foregroundColor(.red)
            case "draft":
                Image(systemName: "circle.fill").foregroundColor(.secondary)
            case "open for comments":
                Image(systemName: "megaphone.fill").foregroundColor(.secondary)
            case "approved":
                Image(systemName: "checkmark.circle.fill").foregroundColor(.secondary)
            case "in progress":
                Image(systemName: "circle.dashed").foregroundColor(.yellow)
            case "todo":
                Image(systemName: "circle.dashed").foregroundColor(.primary)
            case "backlog":
                Image(systemName: "circle.dashed").foregroundColor(.secondary)
            case "completed", "done":
                Image(systemName: "checkmark.circle.fill").foregroundColor(Color(hex: "#5E6AD2"))
            case "canceled", "cancelled":
                Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
            default:
                stateTypeBasedIcon
            }
        }
    }

    @ViewBuilder
    private var stateTypeBasedIcon: some View {
        switch issue.state?.type {
        case "completed":
            Image(systemName: "checkmark.circle.fill").foregroundColor(Color(hex: "#5E6AD2"))
        case "canceled":
            Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
        case "started":
            Image(systemName: "circle.dashed").foregroundColor(.yellow)
        default:
            Image(systemName: "circle.dashed").foregroundColor(.secondary)
        }
    }
}

// MARK: - Project Status Icon

private struct ProjectStatusIcon: View {
    let project: Project

    var body: some View {
        Group {
            if let icon = project.icon, !icon.isEmpty {
                customIconView(icon)
            } else {
                stateBasedIcon
            }
        }
    }

    @ViewBuilder
    private func customIconView(_ icon: String) -> some View {
        if icon.count == 1 {
            Text(icon).font(.system(size: 14))
        } else {
            let isActive = ["started", "in progress", "paused", "completed", "canceled", "cancelled"]
                .contains(project.state.lowercased())
            Image(systemName: SFSymbolMapper.sfSymbol(for: icon))
                .foregroundColor(isActive ? iconColor : .secondary)
        }
    }

    @ViewBuilder
    private var stateBasedIcon: some View {
        switch project.state.lowercased() {
        case "triage":
            Image(systemName: "cube").foregroundColor(.red)
        case "draft":
            Image(systemName: "cube.fill").foregroundColor(.secondary)
        case "planned":
            Image(systemName: "cube").foregroundColor(.secondary)
        case "started", "in progress":
            Image(systemName: "cube").foregroundColor(.yellow)
        case "paused":
            Image(systemName: "cube").foregroundColor(.orange)
        case "completed":
            Image(systemName: "checkmark.circle.fill").foregroundColor(Color(hex: "#5E6AD2"))
        case "canceled", "cancelled":
            Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
        default:
            Image(systemName: "cube").foregroundColor(.secondary)
        }
    }

    private var iconColor: Color {
        switch project.state.lowercased() {
        case "started", "in progress": return .yellow
        case "paused": return .orange
        case "completed": return Color(hex: "#5E6AD2")
        default: return .secondary
        }
    }
}

// MARK: - Initiative Status Icon

private struct InitiativeStatusIcon: View {
    let initiative: Initiative

    var body: some View {
        Group {
            if let icon = initiative.icon, !icon.isEmpty {
                customIconView(icon)
            } else {
                statusBasedIcon
            }
        }
    }

    @ViewBuilder
    private func customIconView(_ icon: String) -> some View {
        if icon.count == 1 {
            Text(icon).font(.system(size: 14))
        } else {
            let isActive = ["active", "completed"].contains(initiative.status?.lowercased() ?? "")
            Image(systemName: SFSymbolMapper.sfSymbol(for: icon))
                .foregroundColor(isActive ? iconColor : .secondary)
        }
    }

    @ViewBuilder
    private var statusBasedIcon: some View {
        switch initiative.status?.lowercased() {
        case "planned":
            Image(systemName: "scope").foregroundColor(.secondary)
        case "active":
            Image(systemName: "scope").foregroundColor(.orange)
        case "completed":
            Image(systemName: "checkmark.circle.fill").foregroundColor(Color(hex: "#5E6AD2"))
        default:
            Image(systemName: "scope").foregroundColor(.secondary)
        }
    }

    private var iconColor: Color {
        switch initiative.status?.lowercased() {
        case "active": return .orange
        case "completed": return Color(hex: "#5E6AD2")
        default: return .secondary
        }
    }
}

// MARK: - Issue Content View

private struct IssueContentView: View {
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

// MARK: - Project Content View

private struct ProjectContentView: View {
    let project: Project

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(project.name)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(1)

            if let description = project.description, !description.isEmpty {
                Text(description)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
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
                .foregroundColor(.secondary)

            if let progress = project.progress {
                Text("\u{2022}")
                    .foregroundColor(.secondary)
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }

            if let lead = project.lead {
                Text("\u{2022}")
                    .foregroundColor(.secondary)
                Text(lead.name)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
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

// MARK: - Initiative Content View

private struct InitiativeContentView: View {
    let initiative: Initiative

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(initiative.name)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(1)

            if let description = initiative.description, !description.isEmpty {
                Text(description)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            if let targetDate = initiative.targetDate {
                HStack(spacing: 6) {
                    DueDateBadge(dueDate: targetDate, isOverdue: initiative.isOverdue)
                }
            }

            if let progress = initiative.progress {
                Text("\(Int(progress * 100))% complete")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Badge Components

private struct DueDateBadge: View {
    let dueDate: String
    let isOverdue: Bool

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: isOverdue ? "calendar.badge.exclamationmark" : "calendar")
                .font(.system(size: 9))
                .foregroundColor(isOverdue ? .red : .secondary)

            Text(formattedDate)
                .font(.system(size: 10))
                .foregroundColor(isOverdue ? .red : .secondary)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(4)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: dueDate) {
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
        return dueDate
    }
}

private struct ProjectBadge: View {
    let project: ProjectReference

    var body: some View {
        HStack(spacing: 3) {
            if let icon = project.icon, !icon.isEmpty, icon.count == 1 {
                Text(icon)
                    .font(.system(size: 9))
            } else {
                Image(systemName: "shippingbox")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }

            Text(project.name)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(4)
    }
}

private struct LabelBadge: View {
    let label: IssueLabel

    var body: some View {
        HStack(spacing: 3) {
            Circle()
                .fill(Color(hex: label.color))
                .frame(width: 6, height: 6)

            Text(label.name)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(4)
    }
}
