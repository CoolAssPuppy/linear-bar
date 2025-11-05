import SwiftUI

/// View displaying recently updated items, filterable by "Me" or "Team"
struct RecentlyUpdatedView: View {
    @ObservedObject private var settings = AppSettings.shared
    @State private var selectedMode: ViewMode = .createdByMe
    @State private var selectedTeam: Team?
    @State private var teams: [Team] = []
    @State private var items: [any LinearItem] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var hasLoadedInitialView = false

    private var filteredItems: [any LinearItem] {
        let filtered = items.filter { item in
            // Filter issues by state type
            if let issue = item as? Issue {
                if let stateType = issue.state?.type {
                    if stateType == "completed" && !settings.showCompletedItems {
                        return false
                    }
                    if stateType == "canceled" && !settings.showCanceledItems {
                        return false
                    }
                }
            }

            // Filter projects by state
            if let project = item as? Project {
                if project.state.lowercased() == "completed" && !settings.showCompletedItems {
                    return false
                }
                if project.state.lowercased() == "canceled" && !settings.showCanceledItems {
                    return false
                }
            }

            // Filter initiatives by status
            if let initiative = item as? Initiative {
                if initiative.status?.lowercased() == "completed" && !settings.showCompletedItems {
                    return false
                }
            }

            return true
        }

        // Apply sort order
        return filtered.sorted { item1, item2 in
            switch settings.sortOrder {
            case .createdNewest:
                let date1 = item1.createdAt ?? Date.distantPast
                let date2 = item2.createdAt ?? Date.distantPast
                return date1 > date2
            case .createdOldest:
                let date1 = item1.createdAt ?? Date.distantPast
                let date2 = item2.createdAt ?? Date.distantPast
                return date1 < date2
            case .updatedNewest:
                let date1 = item1.updatedAt ?? Date.distantPast
                let date2 = item2.updatedAt ?? Date.distantPast
                return date1 > date2
            case .updatedOldest:
                let date1 = item1.updatedAt ?? Date.distantPast
                let date2 = item2.updatedAt ?? Date.distantPast
                return date1 < date2
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            controlsView

            Divider()

            Group {
                if isLoading {
                    loadingView
                } else if let error = errorMessage {
                    errorView(error)
                } else if filteredItems.isEmpty {
                    emptyStateView
                } else {
                    contentView
                }
            }
        }
        .onAppear {
            if !hasLoadedInitialView {
                selectedMode = settings.defaultViewMode
                hasLoadedInitialView = true
            }
            loadData()
        }
        .onReceive(NotificationCenter.default.publisher(for: .refreshAllData)) { _ in
            loadData()
        }
    }

    // MARK: - Controls

    private var controlsView: some View {
        HStack(spacing: 12) {
            Picker("", selection: $selectedMode) {
                Text("Created").tag(ViewMode.createdByMe)
                Text("Assigned").tag(ViewMode.assignedToMe)
                Text("Team").tag(ViewMode.teamItems)
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedMode) { _ in
                loadData()
            }

            if selectedMode == .teamItems && !teams.isEmpty {
                Picker("", selection: $selectedTeam) {
                    ForEach(teams) { team in
                        Text(team.name).tag(team as Team?)
                    }
                }
                .frame(maxWidth: .infinity)
                .onChange(of: selectedTeam) { _ in
                    loadData()
                }
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Content

    private var contentView: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(Array(filteredItems.enumerated()), id: \.offset) { index, item in
                    if let issue = item as? Issue {
                        ItemRow(issue: issue, accountColor: getAccountColor())
                            .padding(.horizontal, 12)
                    } else if let project = item as? Project {
                        ItemRow(project: project, accountColor: getAccountColor())
                            .padding(.horizontal, 12)
                    } else if let initiative = item as? Initiative {
                        ItemRow(initiative: initiative, accountColor: getAccountColor())
                            .padding(.horizontal, 12)
                    }
                }
            }
            .padding(.vertical, 12)
        }
    }

    // MARK: - Loading State

    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .controlSize(.large)
            Text("Loading items...")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .padding(.top, 8)
            Spacer()
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Spacer()

            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            if selectedMode == .createdByMe {
                Text("No items created by you")
                    .font(.headline)
            } else if selectedMode == .assignedToMe {
                Text("No items assigned to you")
                    .font(.headline)
            } else {
                Text("No recent items")
                    .font(.headline)
            }

            Spacer()
        }
        .padding()
    }

    // MARK: - Error State

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Spacer()

            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            Text("Error loading items")
                .font(.headline)

            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Retry") {
                loadData()
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .padding()
    }

    // MARK: - Data Loading

    private func loadData() {
        guard let account = AppSettings.shared.accounts.first(where: { $0.isEnabled && $0.authStatus == .valid }),
              let accessToken = KeychainService.shared.retrieveAccessToken(forAccount: account.email) else {
            errorMessage = "No authenticated account found. Please sign in."
            return
        }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                if selectedMode == .createdByMe {
                    // Load items created by me (issues and projects in parallel)
                    // Note: Initiatives don't have a creator field in Linear's API, so we can't filter them
                    async let issuesResult = LinearAPI.shared.fetchMyIssues(accessToken: accessToken)
                    async let projectsResult = LinearAPI.shared.fetchMyProjects(accessToken: accessToken)

                    let (issues, projects) = try await (issuesResult, projectsResult)

                    var combined: [any LinearItem] = []
                    combined.append(contentsOf: issues)
                    combined.append(contentsOf: projects)

                    await MainActor.run {
                        self.items = combined.sorted { ($0.updatedAt ?? Date.distantPast) > ($1.updatedAt ?? Date.distantPast) }
                        self.isLoading = false
                    }
                } else if selectedMode == .assignedToMe {
                    // Load items assigned to me (issues and projects in parallel)
                    async let issuesResult = LinearAPI.shared.fetchAssignedIssues(accessToken: accessToken)
                    async let projectsResult = LinearAPI.shared.fetchAssignedProjects(accessToken: accessToken)

                    let (issues, projects) = try await (issuesResult, projectsResult)

                    var combined: [any LinearItem] = []
                    combined.append(contentsOf: issues)
                    combined.append(contentsOf: projects)

                    await MainActor.run {
                        self.items = combined.sorted { ($0.updatedAt ?? Date.distantPast) > ($1.updatedAt ?? Date.distantPast) }
                        self.isLoading = false
                    }
                } else {
                    // Load teams first if not loaded
                    if teams.isEmpty {
                        let loadedTeams = try await LinearAPI.shared.fetchTeams(accessToken: accessToken)
                        await MainActor.run {
                            self.teams = loadedTeams
                            self.selectedTeam = loadedTeams.first
                        }
                    }

                    // Load team items (only issues for now, as team projects/initiatives aren't as common)
                    if let teamId = selectedTeam?.id {
                        let issues = try await LinearAPI.shared.fetchTeamIssues(teamId: teamId, accessToken: accessToken)
                        await MainActor.run {
                            self.items = issues.sorted { ($0.updatedAt ?? Date.distantPast) > ($1.updatedAt ?? Date.distantPast) }
                            self.isLoading = false
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }

    private func getAccountColor() -> String? {
        return AppSettings.shared.accounts.first?.color
    }
}
