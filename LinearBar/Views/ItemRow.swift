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
                // Left accent color bar
                if let color = accountColor {
                    Rectangle()
                        .fill(Color(hex: color))
                        .frame(width: 3)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        typeIcon

                        if let issue = issue {
                            issueContent(issue)
                        } else if let project = project {
                            projectContent(project)
                        } else if let initiative = initiative {
                            initiativeContent(initiative)
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
                issueStatusIcon(issue)
            } else if let project = project {
                projectStatusIcon(project)
            } else if let initiative = initiative {
                initiativeStatusIcon(initiative)
            }
        }
        .font(.system(size: 16))
    }

    private func issueStatusIcon(_ issue: Issue) -> some View {
        Group {
            // Match by state name for specific icon/color combinations
            switch issue.state?.name.lowercased() {
            case "triage":
                Image(systemName: "circle.dashed")
                    .foregroundColor(.red)
            case "draft":
                Image(systemName: "circle.fill")
                    .foregroundColor(.secondary)
            case "open for comments":
                Image(systemName: "megaphone.fill")
                    .foregroundColor(.secondary)
            case "approved":
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.secondary)
            case "in progress":
                Image(systemName: "circle.dashed")
                    .foregroundColor(.yellow)
            case "todo":
                Image(systemName: "circle.dashed")
                    .foregroundColor(.primary)
            case "backlog":
                Image(systemName: "circle.dashed")
                    .foregroundColor(.secondary)
            case "completed", "done":
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Color(hex: "#5E6AD2")) // Linear purple
            case "canceled", "cancelled":
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            default:
                // Fallback to type-based matching
                switch issue.state?.type {
                case "completed":
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(hex: "#5E6AD2")) // Linear purple
                case "canceled":
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                case "started":
                    Image(systemName: "circle.dashed")
                        .foregroundColor(.yellow)
                default: // "unstarted" / backlog
                    Image(systemName: "circle.dashed")
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private func projectStatusIcon(_ project: Project) -> some View {
        Group {
            // If project has custom icon
            if let icon = project.icon, !icon.isEmpty {
                if icon.count == 1 {
                    // Single character emoji
                    Text(icon)
                        .font(.system(size: 14))
                } else {
                    // Icon name - map to SF Symbol
                    let isInProgressOrLater = ["started", "in progress", "paused", "completed", "canceled", "cancelled"].contains(project.state.lowercased())
                    Image(systemName: mapLinearIconToSFSymbol(icon))
                        .foregroundColor(isInProgressOrLater ? iconColorForState(project.state) : .secondary)
                }
            } else {
                // No custom icon, use state-based cube icons
                switch project.state.lowercased() {
                case "triage":
                    Image(systemName: "cube")
                        .foregroundColor(.red)
                case "draft":
                    Image(systemName: "cube.fill")
                        .foregroundColor(.secondary)
                case "planned":
                    Image(systemName: "cube")
                        .foregroundColor(.secondary)
                case "started", "in progress":
                    Image(systemName: "cube")
                        .foregroundColor(.yellow)
                case "paused":
                    Image(systemName: "cube")
                        .foregroundColor(.orange)
                case "completed":
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(hex: "#5E6AD2")) // Linear purple
                case "canceled", "cancelled":
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                default:
                    Image(systemName: "cube")
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private func initiativeStatusIcon(_ initiative: Initiative) -> some View {
        Group {
            // If initiative has custom icon
            if let icon = initiative.icon, !icon.isEmpty {
                if icon.count == 1 {
                    // Single character emoji
                    Text(icon)
                        .font(.system(size: 14))
                } else {
                    // Icon name - map to SF Symbol
                    let isActiveOrLater = ["active", "completed"].contains(initiative.status?.lowercased() ?? "")
                    Image(systemName: mapLinearIconToSFSymbol(icon))
                        .foregroundColor(isActiveOrLater ? iconColorForInitiativeStatus(initiative.status) : .secondary)
                }
            } else {
                // No custom icon, use state-based icons
                switch initiative.status?.lowercased() {
                case "planned":
                    Image(systemName: "scope")
                        .foregroundColor(.secondary)
                case "active":
                    Image(systemName: "scope")
                        .foregroundColor(.orange)
                case "completed":
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(hex: "#5E6AD2")) // Linear purple
                default:
                    Image(systemName: "scope")
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Content Views

    private func issueContent(_ issue: Issue) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(issue.identifier)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary)

            Text(issue.title)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .lineLimit(1)

            HStack(spacing: 6) {
                if let state = issue.state {
                    Text(state.name)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }

                if let assignee = issue.assignee {
                    Text("•")
                        .foregroundColor(.secondary)
                    Text(assignee.name)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private func projectContent(_ project: Project) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(project.name)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(1)

            HStack(spacing: 6) {
                Text(normalizeProjectState(project.state))
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)

                if let progress = project.progress {
                    Text("•")
                        .foregroundColor(.secondary)
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }

                if let lead = project.lead {
                    Text("•")
                        .foregroundColor(.secondary)
                    Text(lead.name)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private func initiativeContent(_ initiative: Initiative) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(initiative.name)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(1)

            if let progress = initiative.progress {
                Text("\(Int(progress * 100))% complete")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Actions

    private func openInLinear() {
        var urlString: String?

        if let issue = issue {
            urlString = issue.url
        } else if let project = project {
            urlString = project.url
        } else if let initiative = initiative {
            urlString = initiative.url
        }

        if let urlString = urlString, let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Helper Functions

    private func normalizeProjectState(_ state: String) -> String {
        // Normalize project state names to match Linear's UI
        switch state.lowercased() {
        case "started":
            return "In Progress"
        case "backlog":
            return "Backlog"
        case "planned":
            return "Planned"
        case "paused":
            return "Paused"
        case "completed":
            return "Completed"
        case "canceled":
            return "Canceled"
        default:
            return state.capitalized
        }
    }

    private func mapLinearIconToSFSymbol(_ linearIcon: String) -> String {
        switch linearIcon.lowercased() {
        case "users":
            return "person.2.fill"
        case "calendar":
            return "calendar"
        case "inbox":
            return "tray.fill"
        case "archive":
            return "archivebox.fill"
        case "clock":
            return "clock.fill"
        case "star":
            return "star.fill"
        case "heart":
            return "heart.fill"
        case "bookmark":
            return "bookmark.fill"
        case "flag":
            return "flag.fill"
        case "lightning":
            return "bolt.fill"
        case "fire":
            return "flame.fill"
        case "checkmark":
            return "checkmark.circle.fill"
        case "circle":
            return "circle.fill"
        case "square":
            return "square.fill"
        case "target":
            return "target"
        case "folder":
            return "folder.fill"
        case "document":
            return "doc.fill"
        case "paperclip":
            return "paperclip"
        case "link":
            return "link"
        case "chart":
            return "chart.bar.fill"
        case "graph":
            return "chart.line.uptrend.xyaxis"
        case "briefcase":
            return "briefcase.fill"
        case "home":
            return "house.fill"
        case "settings":
            return "gearshape.fill"
        case "bell":
            return "bell.fill"
        case "message":
            return "message.fill"
        case "mail":
            return "envelope.fill"
        case "search":
            return "magnifyingglass"
        case "filter":
            return "line.3.horizontal.decrease.circle.fill"
        case "sort":
            return "arrow.up.arrow.down"
        case "list":
            return "list.bullet"
        case "grid":
            return "square.grid.2x2.fill"
        case "rocket":
            return "rocket.fill"
        case "trophy":
            return "trophy.fill"
        case "lightbulb":
            return "lightbulb.fill"
        default:
            return "circle.fill"
        }
    }

    private func iconColorForState(_ state: String) -> Color {
        switch state.lowercased() {
        case "started", "in progress":
            return .yellow
        case "paused":
            return .orange
        case "completed":
            return Color(hex: "#5E6AD2") // Linear purple
        case "canceled", "cancelled":
            return .secondary
        default:
            return .secondary
        }
    }

    private func iconColorForInitiativeStatus(_ status: String?) -> Color {
        switch status?.lowercased() {
        case "active":
            return .orange
        case "completed":
            return Color(hex: "#5E6AD2") // Linear purple
        default:
            return .secondary
        }
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
