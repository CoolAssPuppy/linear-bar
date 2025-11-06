import SwiftUI

/// View for searching issues, projects, and initiatives
struct SearchView: View {
    @State private var searchText = ""
    @State private var searchResults: [any LinearItem] = []
    @State private var isSearching = false
    @State private var errorMessage: String?
    @State private var searchTask: Task<Void, Never>?
    @State private var showCompletedItems = true
    @State private var showCanceledItems = false
    @State private var sortOrder: SortOrder = .updatedNewest

    private var filteredResults: [any LinearItem] {
        let filtered = searchResults.filter { item in
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
            searchField

            Divider()

            Group {
                if isSearching {
                    loadingView
                } else if let error = errorMessage {
                    errorView(error)
                } else if searchText.isEmpty {
                    promptView
                } else if filteredResults.isEmpty {
                    emptyResultsView
                } else {
                    resultsView
                }
            }
        }
        .onAppear {
            syncSettingsFromAppSettings()
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
    }

    // MARK: - Search Field

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .font(.system(size: 14))

            TextField("Search issues, projects, initiatives...", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .onChange(of: searchText) { newValue in
                    performSearch(query: newValue)
                }

            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    // MARK: - Results View

    private var resultsView: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(Array(filteredResults.enumerated()), id: \.offset) { index, item in
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
            Text("Searching...")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .padding(.top, 8)
            Spacer()
        }
    }

    // MARK: - Prompt View

    private var promptView: some View {
        VStack(spacing: 12) {
            Spacer()

            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("Search your Linear workspace")
                .font(.headline)

            Text("Type to search across issues, projects, and initiatives")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding()
    }

    // MARK: - Empty Results

    private var emptyResultsView: some View {
        VStack(spacing: 12) {
            Spacer()

            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No results found")
                .font(.headline)

            Text("No results for \"\(searchText)\"")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

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

            Text("Search error")
                .font(.headline)

            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Retry") {
                performSearch(query: searchText)
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .padding()
    }

    // MARK: - Search Logic

    private func performSearch(query: String) {
        // Cancel previous search task
        searchTask?.cancel()

        // Clear results if query is empty
        guard !query.isEmpty else {
            searchResults = []
            errorMessage = nil
            return
        }

        // Debounce search by 500ms
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 500ms

            guard !Task.isCancelled else { return }

            await executeSearch(query: query)
        }
    }

    private func executeSearch(query: String) async {
        guard let account = AppSettings.shared.accounts.first(where: { $0.isEnabled && $0.authStatus == .valid }),
              let accessToken = KeychainService.shared.retrieveAccessToken(forAccount: account.email) else {
            await MainActor.run {
                errorMessage = "No authenticated account found. Please sign in."
            }
            return
        }

        await MainActor.run {
            isSearching = true
            errorMessage = nil
        }

        do {
            // Search issues and projects in parallel
            async let issuesResult = LinearAPI.shared.searchIssues(term: query, accessToken: accessToken)
            async let projectsResult = LinearAPI.shared.searchProjects(term: query, accessToken: accessToken)

            let (issues, projects) = try await (issuesResult, projectsResult)

            // Combine and limit to 10 items total
            var combined: [any LinearItem] = []
            for issue in issues.prefix(7) {
                combined.append(issue)
            }
            for project in projects.prefix(3) {
                combined.append(project)
            }

            await MainActor.run {
                self.searchResults = Array(combined.prefix(10))
                self.isSearching = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isSearching = false
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
