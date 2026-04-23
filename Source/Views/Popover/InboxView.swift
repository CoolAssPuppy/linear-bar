import SwiftUI

/// Primary popover tab. Renders the viewer's unread Linear notifications
/// grouped into Today / Yesterday / Earlier, using a flat row per
/// notification with the actor's avatar on the left and a relative
/// timestamp on the right. See Paper artboard "Popover - Inbox".
struct InboxView: View {
    @State private var notifications: [LinearNotification] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var hasLoadedOnce = false

    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 0) {
            subHeader

            Group {
                if isLoading && notifications.isEmpty {
                    LoadingStateView("Loading inbox…")
                } else if AppSettings.shared.accounts.isEmpty {
                    NoAccountView(message: "Connect your Linear account to see your inbox.")
                } else if let error = errorMessage {
                    ErrorStateView(title: "Could not load inbox", message: error, onRetry: loadData)
                } else if notifications.isEmpty {
                    EmptyStateView(
                        icon: "tray",
                        title: "Inbox zero",
                        subtitle: "No unread notifications right now."
                    )
                } else {
                    contentView
                }
            }
        }
        .onAppear {
            if !hasLoadedOnce {
                hasLoadedOnce = true
                loadData()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .refreshAllData)) { _ in
            loadData()
        }
    }

    // MARK: - Sub-header

    private var subHeader: some View {
        HStack(spacing: 8) {
            TeamFilterChip()
            Spacer(minLength: 0)
            Text(unreadLabel)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(theme.tertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var unreadLabel: String {
        let count = notifications.count
        if count == 0 { return "No unread" }
        if count == 1 { return "1 unread" }
        return "\(count) unread"
    }

    // MARK: - Content

    private var contentView: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: []) {
                ForEach(groupedNotifications, id: \.label) { group in
                    SectionDivider(label: group.label)
                    ForEach(group.notifications) { notification in
                        NotificationRow(notification: notification)
                    }
                }
            }
            .padding(.bottom, 8)
        }
    }

    private struct NotificationGroup {
        let label: String
        let notifications: [LinearNotification]
    }

    private var groupedNotifications: [NotificationGroup] {
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        let startOfYesterday = calendar.date(byAdding: .day, value: -1, to: startOfToday) ?? startOfToday

        var today: [LinearNotification] = []
        var yesterday: [LinearNotification] = []
        var earlier: [LinearNotification] = []

        for notification in notifications.sorted(by: { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }) {
            let createdAt = notification.createdAt ?? .distantPast
            if createdAt >= startOfToday {
                today.append(notification)
            } else if createdAt >= startOfYesterday {
                yesterday.append(notification)
            } else {
                earlier.append(notification)
            }
        }

        var groups: [NotificationGroup] = []
        if !today.isEmpty { groups.append(NotificationGroup(label: "Today", notifications: today)) }
        if !yesterday.isEmpty { groups.append(NotificationGroup(label: "Yesterday", notifications: yesterday)) }
        if !earlier.isEmpty { groups.append(NotificationGroup(label: "Earlier", notifications: earlier)) }
        return groups
    }

    // MARK: - Data

    private func loadData() {
        let accessToken: String
        let accountEmail: String

        if TestDataProvider.isUITesting {
            accessToken = "demo-token"
            accountEmail = "demo@example.com"
        } else {
            guard let account = AppSettings.shared.accounts.first(where: { $0.isEnabled && $0.authStatus == .valid }),
                  let token = KeychainService.shared.retrieveAccessToken(forAccount: account.email) else {
                errorMessage = "No authenticated account found. Please sign in."
                return
            }
            accessToken = token
            accountEmail = account.email
        }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                let items = try await LinearAPI.shared.fetchUnreadNotifications(
                    accessToken: accessToken,
                    accountEmail: accountEmail
                )
                await MainActor.run {
                    notifications = items
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Section divider

private struct SectionDivider: View {
    let label: String

    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: 10) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.8)
                .foregroundStyle(theme.tertiary)
            Rectangle()
                .fill(theme.divider)
                .frame(height: 1)
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 6)
    }
}

// MARK: - Row

private struct NotificationRow: View {
    let notification: LinearNotification

    @Environment(\.theme) private var theme
    @State private var isHovered = false

    var body: some View {
        Button(action: openInLinear) {
            HStack(alignment: .top, spacing: 10) {
                NotificationAvatar(notification: notification)
                content
                Spacer(minLength: 6)
                Text(relativeTimestamp)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(theme.tertiary)
                    .padding(.top, 3)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                isHovered
                    ? RoundedRectangle(cornerRadius: 0, style: .continuous).fill(theme.cardInset)
                    : RoundedRectangle(cornerRadius: 0, style: .continuous).fill(Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Text(notification.actor?.label ?? "Linear")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(notification.isUrgent ? theme.destructive : theme.foreground)
                Text(notification.reasonPhrase)
                    .font(.system(size: 12))
                    .foregroundStyle(theme.muted)
                    .lineLimit(1)
            }

            HStack(spacing: 6) {
                if let identifier = notification.issue?.identifier {
                    Text(identifier)
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundStyle(theme.primary)
                        .fixedSize()
                } else if let project = notification.project {
                    ProjectGlyph(color: project.color)
                    Text(project.name)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(projectLabelColor(project.color))
                        .fixedSize()
                } else if notification.document != nil {
                    InitiativeGlyph()
                }

                Text(targetTitle)
                    .font(.system(size: 11))
                    .foregroundStyle(theme.foregroundSoft)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
    }

    private var targetTitle: String {
        notification.issue?.title
            ?? notification.project?.name
            ?? notification.document?.title
            ?? ""
    }

    private var relativeTimestamp: String {
        guard let createdAt = notification.createdAt else { return "" }
        return RelativeTimeFormatter.shortLabel(for: createdAt)
    }

    private func projectLabelColor(_ hex: String?) -> Color {
        if let hex = hex {
            return Color(hex: hex)
        }
        return theme.warning
    }

    private func openInLinear() {
        guard let url = notification.targetURL else { return }
        NSWorkspace.shared.open(url)
    }
}

// MARK: - Avatar

private struct NotificationAvatar: View {
    let notification: LinearNotification

    @Environment(\.theme) private var theme

    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundColor)
            Text(notification.actor?.initials ?? "LI")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(Color.black.opacity(0.8))
        }
        .frame(width: 22, height: 22)
    }

    /// Pseudo-random but stable color per actor so rows visually separate.
    /// Avoids storing color with the notification and keeps the palette tied
    /// to the theme's accent family.
    private var backgroundColor: Color {
        let id = notification.actor?.id ?? notification.actor?.displayName ?? notification.id
        let hash = id.hashValue
        let palette: [Color] = [
            Color(hex: "#E6B35A"),
            Color(hex: "#7B8BDE"),
            Color(hex: "#27AE60"),
            Color(hex: "#BB6BD9"),
            Color(hex: "#56CCF2"),
            Color(hex: "#EB5757")
        ]
        let index = abs(hash) % palette.count
        return palette[index]
    }
}

// MARK: - Type glyphs

/// Project square with three filled quadrants, mirroring Linear's project
/// iconography. Tinted by the project's accent color.
struct ProjectGlyph: View {
    let color: String?

    @Environment(\.theme) private var theme

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                .fill(tint)
            quadrantOverlay
        }
        .frame(width: 10, height: 10)
    }

    private var tint: Color {
        if let color { return Color(hex: color) }
        return theme.warning
    }

    private var quadrantOverlay: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let half = size.width / 2
            let inset: CGFloat = 0
            Path { path in
                path.addRect(CGRect(x: inset, y: inset, width: half - inset, height: half - inset))
                path.addRect(CGRect(x: half, y: inset, width: half - inset, height: half - inset))
                path.addRect(CGRect(x: inset, y: half, width: half - inset, height: half - inset))
            }
            .fill(Color.white.opacity(0.35))
        }
    }
}

/// Outlined diamond for initiatives, matching the Paper artboard's
/// initiative icon family.
struct InitiativeGlyph: View {
    @Environment(\.theme) private var theme

    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 5, y: 0))
            path.addLine(to: CGPoint(x: 10, y: 5))
            path.addLine(to: CGPoint(x: 5, y: 10))
            path.addLine(to: CGPoint(x: 0, y: 5))
            path.closeSubpath()
        }
        .stroke(initiativeColor, lineWidth: 1.2)
        .background(
            Path { path in
                path.move(to: CGPoint(x: 5, y: 0))
                path.addLine(to: CGPoint(x: 10, y: 5))
                path.addLine(to: CGPoint(x: 5, y: 10))
                path.addLine(to: CGPoint(x: 0, y: 5))
                path.closeSubpath()
            }
            .fill(initiativeColor.opacity(0.18))
        )
        .frame(width: 10, height: 10)
    }

    private var initiativeColor: Color {
        Color(hex: "#BB6BD9")
    }
}

// MARK: - Team filter chip

private struct TeamFilterChip: View {
    @Environment(\.theme) private var theme
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 5) {
            Text("All teams")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(theme.muted)
            Image(systemName: "chevron.down")
                .font(.system(size: 8, weight: .semibold))
                .foregroundStyle(theme.tertiary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(isHovered ? theme.cardInset : Color.clear)
        )
        .onHover { isHovered = $0 }
    }
}
