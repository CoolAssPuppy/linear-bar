import SwiftUI

/// The Mine tab. Flat list of issues assigned to the viewer, sorted by
/// updated or created date. See Paper artboard "Popover - My Issues".
struct MyIssuesView: View {
    @State private var issues: [Issue] = []
    @State private var openIssues: [Issue] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var hasLoadedOnce = false
    @State private var sortMode: MineSort = .updated

    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 0) {
            subHeader

            Group {
                if isLoading && openIssues.isEmpty {
                    LoadingStateView("Loading your issues…")
                } else if AppSettings.shared.accounts.isEmpty {
                    NoAccountView(message: "Connect your Linear account to see your issues.")
                } else if let error = errorMessage {
                    ErrorStateView(title: "Could not load issues", message: error, onRetry: loadData)
                } else if openIssues.isEmpty {
                    EmptyStateView(
                        icon: "checkmark.circle",
                        title: "Nothing on your plate",
                        subtitle: "Issues assigned to you will show up here."
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
        .onChange(of: sortMode) { _, _ in rebuildOpen() }
        .onReceive(NotificationCenter.default.publisher(for: .refreshAllData)) { _ in
            loadData()
        }
    }

    // MARK: - Sub-header

    private var subHeader: some View {
        HStack(spacing: 8) {
            PopoverTeamPlaceholder()
            PopoverChip(
                prefix: "Sort:",
                selection: $sortMode,
                options: MineSort.allCases,
                label: { $0.label }
            )
            Spacer(minLength: 0)
            Text(openLabel)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(theme.tertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var openLabel: String {
        let count = openIssues.count
        if count == 1 { return "1 open" }
        return "\(count) open"
    }

    // MARK: - Content

    private var contentView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(openIssues) { issue in
                    CompactIssueRow(issue: issue)
                }
            }
            .padding(.bottom, 8)
        }
    }

    private func rebuildOpen() {
        let open = issues.filter { $0.state?.isOpen ?? true }
        openIssues = open.sorted { lhs, rhs in
            let lhsDate = sortMode == .updated ? (lhs.updatedAt ?? .distantPast) : (lhs.createdAt ?? .distantPast)
            let rhsDate = sortMode == .updated ? (rhs.updatedAt ?? .distantPast) : (rhs.createdAt ?? .distantPast)
            return lhsDate > rhsDate
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
                let fetched = try await LinearAPI.shared.fetchAssignedIssues(
                    accessToken: session.accessToken,
                    accountEmail: session.accountEmail
                )
                await MainActor.run {
                    issues = fetched
                    rebuildOpen()
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

    enum MineSort: String, CaseIterable, Identifiable {
        case updated, created

        var id: String { rawValue }
        var label: String {
            switch self {
            case .updated: return "Updated"
            case .created: return "Created"
            }
        }
    }
}

