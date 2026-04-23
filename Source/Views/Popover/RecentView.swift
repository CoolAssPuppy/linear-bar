import SwiftUI

/// Recent tab. Merges issues, projects, and initiatives into a single
/// time-ordered list so the user sees every artifact that has moved
/// recently, not just issues. See Paper artboard "Popover - Recent".
struct RecentView: View {
    @State private var issues: [Issue] = []
    @State private var projects: [Project] = []
    @State private var initiatives: [Initiative] = []
    @State private var filtered: [RecentArtifact] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var hasLoadedOnce = false
    @State private var scope: Scope = .touched
    @State private var typeFilter: TypeFilter = .all

    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 0) {
            subHeader

            Group {
                if isLoading && filtered.isEmpty {
                    LoadingStateView("Loading recent activity…")
                } else if AppSettings.shared.accounts.isEmpty {
                    NoAccountView(message: "Connect your Linear account to see recent activity.")
                } else if let error = errorMessage {
                    ErrorStateView(title: "Could not load recent activity", message: error, onRetry: loadData)
                } else if filtered.isEmpty {
                    EmptyStateView(
                        icon: "clock",
                        title: "Nothing recent",
                        subtitle: "Touched issues, projects, and initiatives will show up here."
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
        .onChange(of: scope) { _, _ in loadData() }
        .onChange(of: typeFilter) { _, _ in rebuildFiltered() }
        .onReceive(NotificationCenter.default.publisher(for: .teamFilterChanged)) { _ in
            rebuildFiltered()
        }
        .onReceive(NotificationCenter.default.publisher(for: .refreshAllData)) { _ in
            loadData()
        }
    }

    // MARK: - Sub-header

    private var subHeader: some View {
        HStack(spacing: 8) {
            PopoverTeamChip()
            PopoverChip(
                prefix: nil,
                selection: $typeFilter,
                options: TypeFilter.allCases,
                label: { $0.label }
            )
            PopoverChip(
                prefix: "Scope:",
                selection: $scope,
                options: Scope.allCases,
                label: { $0.label }
            )
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    // MARK: - Content

    private var contentView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(filtered) { item in
                    RecentArtifactRow(item: item)
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

        Task {
            do {
                async let fetchedIssues = LinearAPI.shared.fetchTouchedIssues(
                    accessToken: session.accessToken,
                    accountEmail: session.accountEmail,
                    since: scope.sinceDuration
                )
                async let fetchedProjects = LinearAPI.shared.fetchRecentProjects(
                    accessToken: session.accessToken,
                    accountEmail: session.accountEmail
                )
                async let fetchedInitiatives = LinearAPI.shared.fetchRecentInitiatives(
                    accessToken: session.accessToken,
                    accountEmail: session.accountEmail
                )

                // Projects and initiatives are workspace-wide; allow them to
                // fail independently so a perm error on one type doesn't
                // empty the whole tab.
                let issuesResult = try await fetchedIssues
                let projectsResult = (try? await fetchedProjects) ?? []
                let initiativesResult = (try? await fetchedInitiatives) ?? []

                await MainActor.run {
                    issues = issuesResult
                    projects = projectsResult
                    initiatives = initiativesResult
                    rebuildFiltered()
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

    private func rebuildFiltered() {
        let selectedTeam = AppSettings.shared.selectedTeamId

        var bucket: [RecentArtifact] = []
        if typeFilter.includesIssues {
            bucket.append(contentsOf: issues.map(RecentArtifact.issue))
        }
        if typeFilter.includesProjects {
            bucket.append(contentsOf: projects.map(RecentArtifact.project))
        }
        if typeFilter.includesInitiatives {
            bucket.append(contentsOf: initiatives.map(RecentArtifact.initiative))
        }

        if let selectedTeam {
            bucket = bucket.filter { item in
                // Projects and initiatives aren't team-scoped; surface them
                // regardless of the team filter. Issues still filter by
                // team id.
                if case .issue = item { return item.teamId == selectedTeam }
                return true
            }
        }

        filtered = bucket.sorted {
            ($0.updatedAt ?? .distantPast) > ($1.updatedAt ?? .distantPast)
        }
    }

    enum Scope: String, CaseIterable, Identifiable {
        case touched, week, month

        var id: String { rawValue }
        var label: String {
            switch self {
            case .touched: return "Anything I touched"
            case .week:    return "Last 7 days"
            case .month:   return "Last 30 days"
            }
        }
        var sinceDuration: String {
            switch self {
            case .touched: return "P2W"
            case .week:    return "P1W"
            case .month:   return "P1M"
            }
        }
    }

    enum TypeFilter: String, CaseIterable, Identifiable {
        case all, issues, projects, initiatives

        var id: String { rawValue }
        var label: String {
            switch self {
            case .all:         return "All"
            case .issues:      return "Issues"
            case .projects:    return "Projects"
            case .initiatives: return "Initiatives"
            }
        }
        var includesIssues: Bool      { self == .all || self == .issues }
        var includesProjects: Bool    { self == .all || self == .projects }
        var includesInitiatives: Bool { self == .all || self == .initiatives }
    }
}
