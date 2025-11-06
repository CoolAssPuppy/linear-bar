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
        let filtered = items.filter { item in
            // Filter issues by state type
            if let issue = item as? Issue {
                if let stateType = issue.state?.type {
                    if stateType == "completed" && !showCompletedItems {
                        return false
                    }
                    if stateType == "canceled" && !showCanceledItems {
                        return false
                    }
                }
            }

            // Filter projects by state
            if let project = item as? Project {
                if project.state.lowercased() == "completed" && !showCompletedItems {
                    return false
                }
                if project.state.lowercased() == "canceled" && !showCanceledItems {
                    return false
                }
            }

            // Filter initiatives by status
            if let initiative = item as? Initiative {
                if initiative.status?.lowercased() == "completed" && !showCompletedItems {
                    return false
                }
            }

            return true
        }

        // Apply sort order
        return filtered.sorted { item1, item2 in
            switch sortOrder {
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
            case .dueDate:
                // Get due dates - could be from Issue, Project, or Initiative
                let dueDate1 = getDueDate(from: item1)
                let dueDate2 = getDueDate(from: item2)

                // Items with due dates come first, sorted by due date
                // Items without due dates come after, sorted by created date (newest first)
                switch (dueDate1, dueDate2) {
                case (.some(let date1), .some(let date2)):
                    // Both have due dates - sort by due date (earliest first)
                    return date1 < date2
                case (.some, .none):
                    // Only first has due date - it comes first
                    return true
                case (.none, .some):
                    // Only second has due date - it comes first
                    return false
                case (.none, .none):
                    // Neither has due date - sort by created date (newest first)
                    let created1 = item1.createdAt ?? Date.distantPast
                    let created2 = item2.createdAt ?? Date.distantPast
                    return created1 > created2
                }
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
            syncSettingsFromAppSettings()
            if !hasLoadedInitialView {
                selectedMode = AppSettings.shared.defaultViewMode
                hasLoadedInitialView = true
            }
            loadData()
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

        // Restore selected team from settings
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
                // Team selector button
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

            // Sort button
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

    private func getDueDate(from item: any LinearItem) -> Date? {
        // Use simple DateFormatter for YYYY-MM-DD format
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)

        if let issue = item as? Issue, let dueDate = issue.dueDate {
            return formatter.date(from: dueDate)
        } else if let project = item as? Project, let targetDate = project.targetDate {
            return formatter.date(from: targetDate)
        } else if let initiative = item as? Initiative, let targetDate = initiative.targetDate {
            return formatter.date(from: targetDate)
        }

        return nil
    }
}
