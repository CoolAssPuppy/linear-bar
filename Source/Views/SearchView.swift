import SwiftUI

/// Search tab. Single input that queries issues and projects in parallel
/// and presents the combined list. See Paper artboard "Popover - Search".
struct SearchView: View {
    @State private var searchText = ""
    @State private var searchResults: [any LinearItem] = []
    @State private var isSearching = false
    @State private var errorMessage: String?
    @State private var searchTask: Task<Void, Never>?

    @Environment(\.theme) private var theme
    @FocusState private var inputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            subHeader
            searchField

            // Group fills available space — otherwise a short prompt/empty
            // state would leave leftover space that SwiftUI centers the whole
            // column inside, pushing the search input away from the top.
            Group {
                if isSearching {
                    LoadingStateView("Searching…")
                } else if AppSettings.shared.accounts.isEmpty {
                    NoAccountView(message: "Connect your Linear account to search your workspace.")
                } else if let error = errorMessage {
                    ErrorStateView(title: "Search error", message: error) {
                        performSearch(query: searchText)
                    }
                } else if searchText.isEmpty {
                    promptView
                } else if searchResults.isEmpty {
                    emptyResultsView
                } else {
                    resultsView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                inputFocused = true
            }
        }
    }

    // MARK: - Sub-header

    private var subHeader: some View {
        HStack(spacing: 8) {
            PopoverTeamPlaceholder()
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 6)
    }

    // MARK: - Search field

    private var searchField: some View {
        HStack(spacing: 9) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(theme.tertiary)

            TextField("Search issues, projects, documents", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .foregroundStyle(theme.foreground)
                .focused($inputFocused)
                .onChange(of: searchText) { _, newValue in
                    performSearch(query: newValue)
                }

            if searchText.isEmpty {
                KeyboardHintPill(text: "⌘K")
            } else {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(theme.tertiary)
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous).fill(theme.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous).strokeBorder(theme.border, lineWidth: 1)
        )
        .padding(.horizontal, 14)
        .padding(.bottom, 8)
    }

    // MARK: - Results

    private var resultsView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(searchResults.enumerated()), id: \.offset) { _, item in
                    SearchResultRow(item: item)
                }
            }
            .padding(.bottom, 8)
        }
    }

    private var promptView: some View {
        Text("Start typing to search everything in this workspace.")
            .font(.system(size: 11))
            .foregroundStyle(theme.tertiary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 32)
            .padding(.top, 18)
    }

    private var emptyResultsView: some View {
        EmptyStateView(
            icon: "doc.text.magnifyingglass",
            title: "No results",
            subtitle: "Nothing matches \"\(searchText)\" in this workspace."
        )
    }

    // MARK: - Search

    private func performSearch(query: String) {
        searchTask?.cancel()

        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResults = []
            errorMessage = nil
            return
        }

        searchTask = Task {
            try? await Task.sleep(nanoseconds: 400_000_000)
            guard !Task.isCancelled else { return }
            await executeSearch(query: query)
        }
    }

    private func executeSearch(query: String) async {
        let session: PopoverSession
        do {
            session = try PopoverSession.resolve()
        } catch {
            await MainActor.run { errorMessage = error.localizedDescription }
            return
        }

        await MainActor.run {
            isSearching = true
            errorMessage = nil
        }

        do {
            async let issuesResult = LinearAPI.shared.searchIssues(
                term: query,
                accessToken: session.accessToken,
                accountEmail: session.accountEmail
            )
            async let projectsResult = LinearAPI.shared.searchProjects(
                term: query,
                accessToken: session.accessToken,
                accountEmail: session.accountEmail
            )

            let (issues, projects) = try await (issuesResult, projectsResult)

            var combined: [any LinearItem] = []
            for issue in issues.prefix(7) { combined.append(issue) }
            for project in projects.prefix(3) { combined.append(project) }

            await MainActor.run {
                searchResults = Array(combined.prefix(10))
                isSearching = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isSearching = false
            }
        }
    }
}

// MARK: - Result row

private struct SearchResultRow: View {
    let item: any LinearItem

    @Environment(\.theme) private var theme
    @State private var isHovered = false

    var body: some View {
        Button(action: openInLinear) {
            HStack(spacing: 10) {
                leadingIcon.frame(width: 14, height: 14)

                if let issue = item as? Issue {
                    Text(issue.identifier)
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundStyle(theme.primary)
                        .frame(width: 70, alignment: .leading)
                } else {
                    Spacer().frame(width: 70)
                }

                Text(item.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(theme.foreground)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Rectangle().fill(isHovered ? theme.cardInset : Color.clear))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }

    @ViewBuilder
    private var leadingIcon: some View {
        if let issue = item as? Issue {
            IssueStateCircle(state: issue.state)
        } else if item is Project {
            ProjectGlyph(color: nil)
        } else if item is Initiative {
            InitiativeGlyph()
        }
    }

    private func openInLinear() {
        guard let url = URL(string: item.url) else { return }
        NSWorkspace.shared.open(url)
    }
}

// MARK: - ⌘K pill

private struct KeyboardHintPill: View {
    let text: String

    @Environment(\.theme) private var theme

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(theme.muted)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous).fill(theme.cardInset)
            )
    }
}
