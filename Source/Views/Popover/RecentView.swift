import SwiftUI

/// Issues, projects, and initiatives most recently updated in Linear.
struct RecentView: View {
    @State private var issues: [Issue] = []
    @State private var projects: [Project] = []
    @State private var initiatives: [Initiative] = []
    @State private var filtered: [RecentArtifact] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var hasLoadedOnce = false
    @State private var timeFilter: TimeFilter = .allTime
    @State private var typeFilter: TypeFilter = .all
    @State private var loadTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 0) {
            subHeader

            Group {
                if isLoading && filtered.isEmpty {
                    LoadingStateView("Loading recent updates…")
                } else if AppSettings.shared.accounts.isEmpty {
                    NoAccountView(message: "Connect your Linear account to see recent updates.")
                } else if let error = errorMessage {
                    ErrorStateView(title: "Could not load recent updates", message: error, onRetry: loadData)
                } else if filtered.isEmpty {
                    EmptyStateView(
                        icon: "clock",
                        title: "Nothing updated",
                        subtitle: "Try a longer time period or another team."
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
        .onChange(of: timeFilter) { _, _ in rebuildFiltered() }
        .onChange(of: typeFilter) { _, _ in rebuildFiltered() }
        .onReceive(NotificationCenter.default.publisher(for: .teamFilterChanged)) { _ in
            rebuildFiltered()
        }
        .onReceive(NotificationCenter.default.publisher(for: .refreshAllData)) { _ in
            loadData()
        }
    }

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
                prefix: "Time:",
                selection: $timeFilter,
                options: TimeFilter.allCases,
                label: { $0.label }
            )
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

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
        loadTask?.cancel()

        loadTask = Task {
            do {
                async let fetchedIssues = LinearAPI.shared.fetchRecentlyUpdatedIssues(
                    accessToken: session.accessToken,
                    accountEmail: session.accountEmail
                )
                async let fetchedProjects = LinearAPI.shared.fetchRecentProjects(
                    accessToken: session.accessToken,
                    accountEmail: session.accountEmail
                )
                async let fetchedInitiatives = LinearAPI.shared.fetchRecentInitiatives(
                    accessToken: session.accessToken,
                    accountEmail: session.accountEmail
                )

                let issuesResult = try await fetchedIssues
                let projectsResult: [Project]
                do {
                    projectsResult = try await fetchedProjects
                } catch {
                    AppLogger.error("Could not load recent projects", log: AppLogger.api, error: error)
                    projectsResult = []
                }
                let initiativesResult: [Initiative]
                do {
                    initiativesResult = try await fetchedInitiatives
                } catch {
                    AppLogger.error("Could not load recent initiatives", log: AppLogger.api, error: error)
                    initiativesResult = []
                }

                if Task.isCancelled { return }
                await MainActor.run {
                    issues = issuesResult
                    projects = projectsResult
                    initiatives = initiativesResult
                    rebuildFiltered()
                    isLoading = false
                }
            } catch {
                if Task.isCancelled { return }
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }

    private func rebuildFiltered(now: Date = Date()) {
        let selectedTeam = AppSettings.shared.selectedTeamId
        var results: [RecentArtifact] = []

        if typeFilter.includesIssues {
            results.append(contentsOf: issues.filter { ListFilter.keep($0) }.map(RecentArtifact.issue))
        }
        if typeFilter.includesProjects {
            results.append(contentsOf: projects.filter { ListFilter.keep($0) }.map(RecentArtifact.project))
        }
        if typeFilter.includesInitiatives {
            results.append(contentsOf: initiatives.filter { ListFilter.keep($0) }.map(RecentArtifact.initiative))
        }

        results = results.filter { timeFilter.includes(updatedAt: $0.updatedAt, now: now) }
        if let selectedTeam {
            results = results.filter { $0.matches(teamId: selectedTeam) }
        }
        filtered = results.sorted {
            ($0.updatedAt ?? .distantPast) > ($1.updatedAt ?? .distantPast)
        }
    }

    enum TimeFilter: String, CaseIterable, Identifiable {
        case allTime, week, month

        var id: String { rawValue }

        var label: String {
            switch self {
            case .allTime: return "All Time"
            case .week:    return "Last 7 days"
            case .month:   return "Last 30 days"
            }
        }

        func includes(updatedAt: Date?, now: Date, calendar: Calendar = .current) -> Bool {
            guard self != .allTime else { return true }
            guard let updatedAt else { return false }
            let days = self == .week ? 7 : 30
            guard let cutoff = calendar.date(byAdding: .day, value: -days, to: now) else { return false }
            return updatedAt >= cutoff
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

        var includesIssues: Bool { self == .all || self == .issues }
        var includesProjects: Bool { self == .all || self == .projects }
        var includesInitiatives: Bool { self == .all || self == .initiatives }
    }
}
