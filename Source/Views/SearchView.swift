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
        let options = ItemFilter.FilterOptions(showCompleted: showCompletedItems, showCanceled: showCanceledItems)
        return ItemFilter.filterAndSort(searchResults, options: options, sortOrder: sortOrder)
    }

    var body: some View {
        VStack(spacing: 0) {
            searchField

            Divider()

            Group {
                if isSearching {
                    LoadingStateView("Searching...")
                } else if AppSettings.shared.accounts.isEmpty {
                    NoAccountView(message: "Connect your Linear account to search your issues and projects.")
                } else if let error = errorMessage {
                    ErrorStateView(title: "Search error", message: error) {
                        performSearch(query: searchText)
                    }
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
            DispatchQueue.main.async {
                syncSettingsFromAppSettings()
            }
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
                ForEach(Array(filteredResults.enumerated()), id: \.offset) { _, item in
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

    // MARK: - Prompt View

    private var promptView: some View {
        EmptyStateView(
            icon: "magnifyingglass",
            title: "Search your Linear workspace",
            subtitle: "Type to search across issues, projects, and initiatives"
        )
    }

    // MARK: - Empty Results

    private var emptyResultsView: some View {
        EmptyStateView(
            icon: "doc.text.magnifyingglass",
            title: "No results found",
            subtitle: "No results for \"\(searchText)\""
        )
    }

    // MARK: - Search Logic

    private func performSearch(query: String) {
        searchTask?.cancel()

        guard !query.isEmpty else {
            searchResults = []
            errorMessage = nil
            return
        }

        searchTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000)

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
            async let issuesResult = LinearAPI.shared.searchIssues(term: query, accessToken: accessToken, accountEmail: account.email)
            async let projectsResult = LinearAPI.shared.searchProjects(term: query, accessToken: accessToken, accountEmail: account.email)

            let (issues, projects) = try await (issuesResult, projectsResult)

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
}
