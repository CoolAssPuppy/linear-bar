import SwiftUI

/// View displaying recently updated items, filterable by "Me" or "Team"
struct RecentlyUpdatedView: View {
    @State private var selectedMode: ViewMode = .createdByMe
    @State private var selectedTeam: Team?
    @State private var teams: [Team] = []
    @State private var items: [any LinearItem] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var hasLoadedInitialView = false
    @State private var showCompletedItems = true
    @State private var showCanceledItems = false
    @State private var sortOrder: SortOrder = .updatedNewest

    private var filteredItems: [any LinearItem] {
        let options = ItemFilter.FilterOptions(showCompleted: showCompletedItems, showCanceled: showCanceledItems)
        return ItemFilter.filterAndSort(items, options: options, sortOrder: sortOrder)
    }

    var body: some View {
        VStack(spacing: 0) {
            controlsView

            Divider()

            Group {
                if isLoading {
                    LoadingStateView("Loading items...")
                } else if AppSettings.shared.accounts.isEmpty {
                    NoAccountView(message: "Connect your Linear account to see your recent issues and projects.")
                } else if let error = errorMessage {
                    ErrorStateView(title: "Error loading items", message: error, onRetry: loadData)
                } else if filteredItems.isEmpty {
                    emptyStateView
                } else {
                    contentView
                }
            }
        }
        .onAppear {
            DispatchQueue.main.async {
                syncSettingsFromAppSettings()
                if !hasLoadedInitialView {
                    selectedMode = AppSettings.shared.defaultViewMode
                    hasLoadedInitialView = true
                }
                loadData()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .refreshAllData)) { _ in
            loadData()
        }
        .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
            syncSettingsFromAppSettings()
        }
    }

    private func syncSettingsFromAppSettings() {
        let settings = AppSettings.shared
        showCompletedItems = settings.showCompletedItems
        showCanceledItems = settings.showCanceledItems
        sortOrder = settings.sortOrder

        if let savedTeamId = settings.selectedTeamId {
            selectedTeam = teams.first(where: { $0.id == savedTeamId })
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

            Spacer()

            if selectedMode == .teamItems && !teams.isEmpty {
                teamSelectorMenu
            }

            sortOrderMenu
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var teamSelectorMenu: some View {
        Menu {
            ForEach(teams) { team in
                Button(action: {
                    selectedTeam = team
                    AppSettings.shared.selectedTeamId = team.id
                    AppSettings.shared.selectedTeamKey = team.key
                    loadData()
                }) {
                    HStack {
                        Text(team.name)
                        if selectedTeam?.id == team.id {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "person.2.fill")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .menuStyle(.borderlessButton)
        .help("Select Team")
    }

    private var sortOrderMenu: some View {
        Menu {
            ForEach(SortOrder.allCases) { order in
                Button(action: {
                    sortOrder = order
                    AppSettings.shared.sortOrder = order
                }) {
                    HStack {
                        Text(order.rawValue)
                        if sortOrder == order {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .menuStyle(.borderlessButton)
        .help("Sort Order")
    }

    // MARK: - Content

    private var contentView: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(Array(filteredItems.enumerated()), id: \.offset) { _, item in
                    itemRow(for: item)
                        .padding(.horizontal, 12)
                }
            }
            .padding(.vertical, 12)
        }
    }

    @ViewBuilder
    private func itemRow(for item: any LinearItem) -> some View {
        if let issue = item as? Issue {
            ItemRow(issue: issue, accountColor: AppSettings.shared.primaryAccountColor)
        } else if let project = item as? Project {
            ItemRow(project: project, accountColor: AppSettings.shared.primaryAccountColor)
        } else if let initiative = item as? Initiative {
            ItemRow(initiative: initiative, accountColor: AppSettings.shared.primaryAccountColor)
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        let (title, subtitle) = emptyStateContent
        return EmptyStateView(icon: "tray", title: title, subtitle: subtitle)
    }

    private var emptyStateContent: (title: String, subtitle: String) {
        switch selectedMode {
        case .createdByMe:
            return ("No items created by you", "Create issues or projects in Linear to see them here")
        case .assignedToMe:
            return ("No items assigned to you", "Get assigned to issues or projects to see them here")
        case .teamItems:
            return ("No recent items", "Your team's items will appear here")
        }
    }

    // MARK: - Data Loading

    private func loadData() {
        // Check for demo mode first
        let isDemoMode = TestDataProvider.isUITesting

        // In demo mode, use a dummy token since the API will return test data
        let accessToken: String
        let accountEmail: String

        if isDemoMode {
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
                let loadedItems = try await loadItemsForMode(accessToken: accessToken, accountEmail: accountEmail)
                await MainActor.run {
                    self.items = loadedItems
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }

    private func loadItemsForMode(accessToken: String, accountEmail: String) async throws -> [any LinearItem] {
        switch selectedMode {
        case .createdByMe:
            return try await loadCreatedByMeItems(accessToken: accessToken, accountEmail: accountEmail)
        case .assignedToMe:
            return try await loadAssignedToMeItems(accessToken: accessToken, accountEmail: accountEmail)
        case .teamItems:
            return try await loadTeamItems(accessToken: accessToken, accountEmail: accountEmail)
        }
    }

    private func loadCreatedByMeItems(accessToken: String, accountEmail: String) async throws -> [any LinearItem] {
        async let issuesResult = LinearAPI.shared.fetchMyIssues(accessToken: accessToken, accountEmail: accountEmail)
        async let projectsResult = LinearAPI.shared.fetchMyProjects(accessToken: accessToken, accountEmail: accountEmail)

        let (issues, projects) = try await (issuesResult, projectsResult)

        var combined: [any LinearItem] = []
        combined.append(contentsOf: issues)
        combined.append(contentsOf: projects)

        return combined.sorted { ($0.updatedAt ?? Date.distantPast) > ($1.updatedAt ?? Date.distantPast) }
    }

    private func loadAssignedToMeItems(accessToken: String, accountEmail: String) async throws -> [any LinearItem] {
        async let issuesResult = LinearAPI.shared.fetchAssignedIssues(accessToken: accessToken, accountEmail: accountEmail)
        async let projectsResult = LinearAPI.shared.fetchAssignedProjects(accessToken: accessToken, accountEmail: accountEmail)

        let (issues, projects) = try await (issuesResult, projectsResult)

        var combined: [any LinearItem] = []
        combined.append(contentsOf: issues)
        combined.append(contentsOf: projects)

        return combined.sorted { ($0.updatedAt ?? Date.distantPast) > ($1.updatedAt ?? Date.distantPast) }
    }

    private func loadTeamItems(accessToken: String, accountEmail: String) async throws -> [any LinearItem] {
        if teams.isEmpty {
            let loadedTeams = try await LinearAPI.shared.fetchTeams(accessToken: accessToken, accountEmail: accountEmail)
            await MainActor.run {
                self.teams = loadedTeams
                // Restore previously selected team from settings, or default to first team
                if let savedTeamId = AppSettings.shared.selectedTeamId,
                   let savedTeam = loadedTeams.first(where: { $0.id == savedTeamId }) {
                    self.selectedTeam = savedTeam
                } else {
                    self.selectedTeam = loadedTeams.first
                    // Save the default selection
                    if let firstTeam = loadedTeams.first {
                        AppSettings.shared.selectedTeamId = firstTeam.id
                        AppSettings.shared.selectedTeamKey = firstTeam.key
                    }
                }
            }
        }

        guard let teamId = selectedTeam?.id else {
            return []
        }

        let issues = try await LinearAPI.shared.fetchTeamIssues(teamId: teamId, accessToken: accessToken, accountEmail: accountEmail)
        return issues.sorted { ($0.updatedAt ?? Date.distantPast) > ($1.updatedAt ?? Date.distantPast) }
    }
}
