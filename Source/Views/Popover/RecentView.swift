import SwiftUI

/// Recent tab. Flat list of Linear artifacts the viewer has touched or
/// watched, sorted by last-updated across authors. Reuses `CompactIssueRow`
/// with the `.actorAndTime` trailing variant. See Paper artboard
/// "Popover - Recent".
struct RecentView: View {
    @State private var items: [Issue] = []
    @State private var sortedItems: [Issue] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var hasLoadedOnce = false
    @State private var scope: Scope = .touched

    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 0) {
            subHeader

            Group {
                if isLoading && sortedItems.isEmpty {
                    LoadingStateView("Loading recent activity…")
                } else if AppSettings.shared.accounts.isEmpty {
                    NoAccountView(message: "Connect your Linear account to see recent activity.")
                } else if let error = errorMessage {
                    ErrorStateView(title: "Could not load recent activity", message: error, onRetry: loadData)
                } else if sortedItems.isEmpty {
                    EmptyStateView(
                        icon: "clock",
                        title: "Nothing recent",
                        subtitle: "Issues you touch will show up here."
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
        .onReceive(NotificationCenter.default.publisher(for: .refreshAllData)) { _ in
            loadData()
        }
    }

    // MARK: - Sub-header

    private var subHeader: some View {
        HStack(spacing: 8) {
            PopoverTeamPlaceholder()
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
                ForEach(sortedItems) { issue in
                    CompactIssueRow(recentIssue: issue)
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
                let fetched = try await LinearAPI.shared.fetchTouchedIssues(
                    accessToken: session.accessToken,
                    accountEmail: session.accountEmail,
                    since: scope.sinceDuration
                )
                await MainActor.run {
                    items = fetched
                    sortedItems = fetched.sorted { ($0.updatedAt ?? .distantPast) > ($1.updatedAt ?? .distantPast) }
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
}
