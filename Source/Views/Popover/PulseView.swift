import SwiftUI

/// Pulse tab. Shows the selected team's recently edited issues, projects,
/// and initiatives in updated order, with a 14-day activity bar chart at
/// the top. Scoped strictly to one team — the team picker lives in the
/// subheader. See Paper artboard "Popover - Pulse".
struct PulseView: View {
    @State private var issues: [Issue] = []
    @State private var projects: [Project] = []
    @State private var initiatives: [Initiative] = []
    @State private var merged: [RecentArtifact] = []
    @State private var buckets: [ActivitySpark.DayBucket] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var hasLoadedOnce = false

    @ObservedObject private var teamsStore = TeamsStore.shared
    @ObservedObject private var settings = AppSettings.shared
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 0) {
            subHeader

            Group {
                if isLoading && merged.isEmpty {
                    LoadingStateView("Loading activity…")
                } else if AppSettings.shared.accounts.isEmpty {
                    NoAccountView(message: "Connect your Linear account to see team activity.")
                } else if let error = errorMessage {
                    ErrorStateView(title: "Could not load activity", message: error, onRetry: loadData)
                } else if merged.isEmpty {
                    EmptyStateView(
                        icon: "waveform.path.ecg",
                        title: "Nothing recent",
                        subtitle: "No activity on this team in the last two weeks."
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
        .onReceive(NotificationCenter.default.publisher(for: .teamFilterChanged)) { _ in
            loadData()
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
            liveIndicator
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var liveIndicator: some View {
        HStack(spacing: 5) {
            Circle().fill(theme.success).frame(width: 6, height: 6)
            Text("Live")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(theme.tertiary)
        }
    }

    // MARK: - Content

    private var contentView: some View {
        ScrollView {
            VStack(spacing: 0) {
                ActivitySpark(buckets: buckets)
                    .padding(.horizontal, 14)
                    .padding(.top, 4)
                    .padding(.bottom, 10)

                PopoverSectionDivider(label: "Recently edited", count: merged.count)

                LazyVStack(spacing: 0) {
                    ForEach(merged) { item in
                        RecentArtifactRow(item: item)
                    }
                }

                Spacer(minLength: 8)
            }
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

        Task {
            do {
                let teamId = settings.selectedTeamId
                async let fetchedIssues: [Issue] = {
                    if let teamId {
                        return try await LinearAPI.shared.fetchTeamIssues(
                            teamId: teamId,
                            accessToken: session.accessToken,
                            accountEmail: session.accountEmail
                        )
                    }
                    return try await LinearAPI.shared.fetchTouchedIssues(
                        accessToken: session.accessToken,
                        accountEmail: session.accountEmail,
                        since: "P2W"
                    )
                }()
                async let fetchedProjects = LinearAPI.shared.fetchRecentProjects(
                    accessToken: session.accessToken,
                    accountEmail: session.accountEmail
                )
                async let fetchedInitiatives = LinearAPI.shared.fetchRecentInitiatives(
                    accessToken: session.accessToken,
                    accountEmail: session.accountEmail
                )

                // Let projects and initiatives fail soft — some workspaces
                // restrict either; an issue-only Pulse is still useful.
                let issuesResult = try await fetchedIssues
                let projectsResult = (try? await fetchedProjects) ?? []
                let initiativesResult = (try? await fetchedInitiatives) ?? []

                await MainActor.run {
                    issues = issuesResult
                    projects = projectsResult
                    initiatives = initiativesResult
                    rebuild()
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

    private func rebuild() {
        // Activity spark: all three types, regardless of team filter. Team
        // scoping for projects/initiatives isn't available in the schema we
        // query, so we show workspace-level activity for those.
        buckets = ActivityBucketer.buckets(
            issues: issues,
            projects: projects,
            initiatives: initiatives
        )

        var combined: [RecentArtifact] = []
        combined.append(contentsOf: issues.map(RecentArtifact.issue))
        combined.append(contentsOf: projects.map(RecentArtifact.project))
        combined.append(contentsOf: initiatives.map(RecentArtifact.initiative))

        merged = combined.sorted {
            ($0.updatedAt ?? .distantPast) > ($1.updatedAt ?? .distantPast)
        }
    }
}
