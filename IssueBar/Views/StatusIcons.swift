import SwiftUI

// MARK: - Issue Status Icon

struct IssueStatusIcon: View {
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

struct ProjectStatusIcon: View {
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

struct InitiativeStatusIcon: View {
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
