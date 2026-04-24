import SwiftUI

/// Primary popover tab. Renders the viewer's unread Linear notifications
/// grouped into Today / Yesterday / Earlier. See Paper artboard
/// "Popover - Inbox".
struct InboxView: View {
    @State private var notifications: [LinearNotification] = []
    @State private var groups: [NotificationGroup] = []
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
        .onReceive(NotificationCenter.default.publisher(for: .teamFilterChanged)) { _ in
            rebuildGroups()
        }
        .onReceive(NotificationCenter.default.publisher(for: .refreshAllData)) { _ in
            loadData()
        }
    }

    // MARK: - Sub-header

    private var subHeader: some View {
        HStack(spacing: 8) {
            PopoverTeamChip()
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
            LazyVStack(spacing: 0) {
                ForEach(groups) { group in
                    PopoverSectionDivider(label: group.label)
                    ForEach(group.notifications) { notification in
                        NotificationRow(notification: notification)
                    }
                }
            }
            .padding(.bottom, 8)
        }
    }

    private func rebuildGroups() {
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        let startOfYesterday = calendar.date(byAdding: .day, value: -1, to: startOfToday) ?? startOfToday
        let selectedTeam = AppSettings.shared.selectedTeamId

        var today: [LinearNotification] = []
        var yesterday: [LinearNotification] = []
        var earlier: [LinearNotification] = []

        let filtered: [LinearNotification]
        if let selectedTeam {
            // Notifications about projects/documents don't carry a team id,
            // so team filtering applies only to issue-targeted rows.
            filtered = notifications.filter { notif in
                if let teamId = notif.issue?.team?.id { return teamId == selectedTeam }
                return false
            }
        } else {
            filtered = notifications
        }

        let sorted = filtered.sorted {
            ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast)
        }

        for notification in sorted {
            let createdAt = notification.createdAt ?? .distantPast
            if createdAt >= startOfToday {
                today.append(notification)
            } else if createdAt >= startOfYesterday {
                yesterday.append(notification)
            } else {
                earlier.append(notification)
            }
        }

        var built: [NotificationGroup] = []
        if !today.isEmpty { built.append(NotificationGroup(label: "Today", notifications: today)) }
        if !yesterday.isEmpty { built.append(NotificationGroup(label: "Yesterday", notifications: yesterday)) }
        if !earlier.isEmpty { built.append(NotificationGroup(label: "Earlier", notifications: earlier)) }
        groups = built
    }

    struct NotificationGroup: Identifiable {
        let label: String
        let notifications: [LinearNotification]
        var id: String { label }
    }

    // MARK: - Data

    private func loadData() {
        let session: PopoverSession
        do {
            session = try PopoverSession.resolve()
        } catch {
            errorMessage = error.localizedDescription
            return
        }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                let items = try await LinearAPI.shared.fetchUnreadNotifications(
                    accessToken: session.accessToken,
                    accountEmail: session.accountEmail
                )
                await MainActor.run {
                    notifications = items
                    rebuildGroups()
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
                Text(RelativeTimeFormatter.shortLabel(for: notification.createdAt ?? Date()))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(theme.tertiary)
                    .padding(.top, 3)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(Rectangle().fill(isHovered ? theme.cardInset : Color.clear))
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

    private func projectLabelColor(_ hex: String?) -> Color {
        if let hex { return Color(hex: hex) }
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

    var body: some View {
        ZStack {
            if let urlString = notification.actor?.avatarUrl,
               let url = SafeExternalURL.httpsURL(from: urlString) {
                AsyncImage(url: url, transaction: Transaction(animation: .default)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        initialsCircle
                    }
                }
            } else {
                initialsCircle
            }
        }
        .frame(width: 22, height: 22)
        .clipShape(Circle())
    }

    private var initialsCircle: some View {
        ZStack {
            Circle().fill(backgroundColor)
            Text(PersonName.initials(from: notification.actor?.label))
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(Color.black.opacity(0.8))
        }
    }

    /// Stable pseudo-random color per actor. UTF-8 sum instead of
    /// `Int.hashValue` because the latter is re-seeded per process and
    /// would shuffle avatar colors on every launch.
    private var backgroundColor: Color {
        let identity = notification.actor?.id
            ?? notification.actor?.displayName
            ?? notification.id
        let digest = identity.utf8.reduce(0) { ($0 &+ Int($1)) & 0x7FFFFFFF }
        return Self.palette[digest % Self.palette.count]
    }

    private static let palette: [Color] = [
        Color(hex: "#E6B35A"),
        Color(hex: "#7B8BDE"),
        Color(hex: "#27AE60"),
        Color(hex: "#BB6BD9"),
        Color(hex: "#56CCF2"),
        Color(hex: "#EB5757")
    ]
}
