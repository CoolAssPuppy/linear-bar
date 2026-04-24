import SwiftUI
import AppKit

/// Pulse tab. Mirrors Linear's web Pulse feed — a chronological stream
/// of project status updates across the workspace, each tagged with the
/// author's health classification (On track / At risk / Off track).
struct PulseView: View {
    @State private var updates: [LinearPulseUpdate] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var hasLoadedOnce = false
    @State private var scope: LinearAPI.PulseScope = .workspace

    @ObservedObject private var teamsStore = TeamsStore.shared
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 0) {
            subHeader

            Group {
                if isLoading && updates.isEmpty {
                    LoadingStateView("Loading pulse…")
                } else if AppSettings.shared.accounts.isEmpty {
                    NoAccountView(message: "Connect your Linear account to see workspace pulse.")
                } else if let error = errorMessage {
                    ErrorStateView(title: "Could not load pulse", message: error, onRetry: loadData)
                } else if updates.isEmpty {
                    EmptyStateView(
                        icon: "waveform.path.ecg",
                        title: "No recent updates",
                        subtitle: "Project status updates will show up here as they're posted."
                    )
                } else {
                    contentView
                }
            }
        }
        .onAppear {
            teamsStore.loadIfNeeded()
            if !hasLoadedOnce {
                hasLoadedOnce = true
                loadData()
            }
        }
        .onChange(of: scope) { _, _ in loadData() }
        .onReceive(NotificationCenter.default.publisher(for: .refreshAllData)) { _ in
            loadData()
        }
    }

    // MARK: - Sub-header

    private var subHeader: some View {
        HStack(spacing: 8) {
            PopoverChip(
                prefix: "Scope:",
                selection: $scope,
                options: LinearAPI.PulseScope.allCases,
                label: { Self.scopeLabel(for: $0) },
                selectionWeight: .foreground
            )
            Spacer(minLength: 0)
            Text(countLabel)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(theme.tertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private static func scopeLabel(for scope: LinearAPI.PulseScope) -> String {
        switch scope {
        case .workspace: return "My Workspace"
        case .teams:     return "My Teams"
        case .mine:      return "Just Mine"
        }
    }

    private var countLabel: String {
        switch updates.count {
        case 0:  return ""
        case 1:  return "1 update"
        default: return "\(updates.count) updates"
        }
    }

    // MARK: - Content

    private var contentView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(updates) { update in
                    PulseRow(update: update)
                    Divider().background(theme.dividerSubtle)
                }
            }
            .padding(.bottom, 8)
        }
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

        let currentScope = scope
        let teamIds = Set(teamsStore.teams.map { $0.id })
        Task {
            do {
                let fetched = try await LinearAPI.shared.fetchPulseUpdates(
                    accessToken: session.accessToken,
                    accountEmail: session.accountEmail,
                    scope: currentScope,
                    viewerTeamIds: teamIds
                )
                await MainActor.run {
                    updates = fetched
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

private struct PulseRow: View {
    let update: LinearPulseUpdate

    @Environment(\.theme) private var theme
    @State private var isHovered = false

    var body: some View {
        Button(action: openInLinear) {
            HStack(alignment: .top, spacing: 10) {
                avatar

                VStack(alignment: .leading, spacing: 4) {
                    header
                    bodyText
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Rectangle().fill(isHovered ? theme.cardInset : Color.clear))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }

    private var header: some View {
        HStack(spacing: 6) {
            Text(update.user?.label ?? "Someone")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(theme.foreground)
                .lineLimit(1)

            Text("on")
                .font(.system(size: 11))
                .foregroundStyle(theme.muted)

            targetGlyph
            Text(targetName)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(theme.foregroundSoft)
                .lineLimit(1)
                .truncationMode(.tail)

            // Health pill only applies to project updates; initiative
            // updates on Linear don't carry a health classification.
            if update.project != nil {
                healthChip
            }

            Spacer(minLength: 6)

            if let createdAt = update.createdAt {
                Text(RelativeTimeFormatter.shortLabel(for: createdAt))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(theme.tertiary)
                    .fixedSize()
            }
        }
    }

    @ViewBuilder
    private var targetGlyph: some View {
        if let project = update.project {
            ProjectGlyph(color: project.color)
        } else if update.initiative != nil {
            InitiativeGlyph()
        }
    }

    private var targetName: String {
        update.project?.name ?? update.initiative?.name ?? ""
    }

    private var targetURL: String? {
        update.project?.url ?? update.initiative?.url
    }

    private var healthChip: some View {
        let health = ProjectUpdateHealth(rawValue: update.health)
        return Text(health.label)
            .font(.system(size: 9, weight: .semibold))
            .tracking(0.2)
            .foregroundStyle(healthForeground(for: health))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule().fill(healthBackground(for: health))
            )
            .overlay(
                Capsule().strokeBorder(healthForeground(for: health).opacity(0.3), lineWidth: 0.5)
            )
            .fixedSize()
    }

    private var bodyText: some View {
        Text(bodyPreview)
            .font(.system(size: 11))
            .foregroundStyle(theme.foregroundSoft)
            .lineLimit(3)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var bodyPreview: String {
        let trimmed = update.body.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "(no update body)" }
        return trimmed
    }

    private var avatar: some View {
        ZStack {
            if let urlString = update.user?.avatarUrl,
               let url = SafeExternalURL.httpsURL(from: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        initialsTile
                    }
                }
            } else {
                initialsTile
            }
        }
        .frame(width: 28, height: 28)
        .clipShape(Circle())
    }

    private var initialsTile: some View {
        ZStack {
            Circle().fill(theme.card)
            Text(PersonName.initials(from: update.user?.label))
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(theme.muted)
        }
    }

    private func healthBackground(for health: ProjectUpdateHealth) -> Color {
        switch health {
        case .onTrack:            return theme.success.opacity(0.12)
        case .atRisk:             return theme.warning.opacity(0.15)
        case .offTrack:           return theme.destructive.opacity(0.14)
        case .unknown:            return theme.card
        }
    }

    private func healthForeground(for health: ProjectUpdateHealth) -> Color {
        switch health {
        case .onTrack:            return theme.success
        case .atRisk:             return theme.warning
        case .offTrack:           return theme.destructive
        case .unknown:            return theme.muted
        }
    }

    private func openInLinear() {
        guard let urlString = targetURL else { return }
        _ = SafeExternalURL.openLinearURL(from: urlString)
    }
}
