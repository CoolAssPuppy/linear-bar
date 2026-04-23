import SwiftUI

// MARK: - Issue Status Icon

struct IssueStatusIcon: View {
    let issue: Issue

    @Environment(\.theme) private var theme

    var body: some View {
        Group {
            switch issue.state?.name.lowercased() {
            case "triage":
                Image(systemName: "circle.dashed").foregroundStyle(theme.destructive)
            case "draft":
                Image(systemName: "circle.fill").foregroundStyle(theme.muted)
            case "open for comments":
                Image(systemName: "megaphone.fill").foregroundStyle(theme.muted)
            case "approved":
                Image(systemName: "checkmark.circle.fill").foregroundStyle(theme.muted)
            case "in progress":
                Image(systemName: "circle.dashed").foregroundStyle(theme.warning)
            case "todo":
                Image(systemName: "circle.dashed").foregroundStyle(theme.foreground)
            case "backlog":
                Image(systemName: "circle.dashed").foregroundStyle(theme.muted)
            case "completed", "done":
                Image(systemName: "checkmark.circle.fill").foregroundStyle(theme.primary)
            case "canceled", "cancelled":
                Image(systemName: "xmark.circle.fill").foregroundStyle(theme.muted)
            default:
                stateTypeBasedIcon
            }
        }
    }

    @ViewBuilder
    private var stateTypeBasedIcon: some View {
        switch issue.state?.type {
        case "completed":
            Image(systemName: "checkmark.circle.fill").foregroundStyle(theme.primary)
        case "canceled":
            Image(systemName: "xmark.circle.fill").foregroundStyle(theme.muted)
        case "started":
            Image(systemName: "circle.dashed").foregroundStyle(theme.warning)
        default:
            Image(systemName: "circle.dashed").foregroundStyle(theme.muted)
        }
    }
}

// MARK: - Project Status Icon

struct ProjectStatusIcon: View {
    let project: Project

    @Environment(\.theme) private var theme

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
                .foregroundStyle(isActive ? iconColor : theme.muted)
        }
    }

    @ViewBuilder
    private var stateBasedIcon: some View {
        switch project.state.lowercased() {
        case "triage":
            Image(systemName: "cube").foregroundStyle(theme.destructive)
        case "draft":
            Image(systemName: "cube.fill").foregroundStyle(theme.muted)
        case "planned":
            Image(systemName: "cube").foregroundStyle(theme.muted)
        case "started", "in progress":
            Image(systemName: "cube").foregroundStyle(theme.warning)
        case "paused":
            Image(systemName: "cube").foregroundStyle(theme.warning)
        case "completed":
            Image(systemName: "checkmark.circle.fill").foregroundStyle(theme.primary)
        case "canceled", "cancelled":
            Image(systemName: "xmark.circle.fill").foregroundStyle(theme.muted)
        default:
            Image(systemName: "cube").foregroundStyle(theme.muted)
        }
    }

    private var iconColor: Color {
        switch project.state.lowercased() {
        case "started", "in progress": return theme.warning
        case "paused": return theme.warning
        case "completed": return theme.primary
        default: return theme.muted
        }
    }
}

// MARK: - Initiative Status Icon

struct InitiativeStatusIcon: View {
    let initiative: Initiative

    @Environment(\.theme) private var theme

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
                .foregroundStyle(isActive ? iconColor : theme.muted)
        }
    }

    @ViewBuilder
    private var statusBasedIcon: some View {
        switch initiative.status?.lowercased() {
        case "planned":
            Image(systemName: "scope").foregroundStyle(theme.muted)
        case "active":
            Image(systemName: "scope").foregroundStyle(theme.warning)
        case "completed":
            Image(systemName: "checkmark.circle.fill").foregroundStyle(theme.primary)
        default:
            Image(systemName: "scope").foregroundStyle(theme.muted)
        }
    }

    private var iconColor: Color {
        switch initiative.status?.lowercased() {
        case "active": return theme.warning
        case "completed": return theme.primary
        default: return theme.muted
        }
    }
}
