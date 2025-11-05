import SwiftUI

/// View for searching issues, projects, and initiatives
struct SearchView: View {
    @ObservedObject private var settings = AppSettings.shared
    @State private var searchText = ""
    @State private var searchResults: [any LinearItem] = []
    @State private var isSearching = false
    @State private var errorMessage: String?
    @State private var searchTask: Task<Void, Never>?

    private var filteredResults: [any LinearItem] {
        searchResults.filter { item in
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
}
