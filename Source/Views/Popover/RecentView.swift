import SwiftUI

/// Recent tab. Flat list of Linear artifacts the viewer has touched or
/// watched, sorted by last-updated across authors. Distinguishes issues,
/// projects, and initiatives via the leading glyph. See Paper artboard
/// "Popover - Recent".
struct RecentView: View {
    @State private var items: [Issue] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var hasLoadedOnce = false
    @State private var scope: Scope = .touched

    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 0) {
            subHeader

            Group {
                if isLoading && items.isEmpty {
                    LoadingStateView("Loading recent activity…")
                } else if AppSettings.shared.accounts.isEmpty {
                    NoAccountView(message: "Connect your Linear account to see recent activity.")
                } else if let error = errorMessage {
                    ErrorStateView(title: "Could not load recent activity", message: error, onRetry: loadData)
                } else if items.isEmpty {
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
        .onReceive(NotificationCenter.default.publisher(for: .refreshAllData)) { _ in
            loadData()
        }
    }

    // MARK: - Sub-header

    private var subHeader: some View {
        HStack(spacing: 8) {
            PopoverTeamChip()
            ScopeChip(scope: $scope)
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
                    RecentRow(issue: issue)
                }
            }
            .padding(.bottom, 8)
        }
    }

    private var sortedItems: [Issue] {
        items.sorted { ($0.updatedAt ?? .distantPast) > ($1.updatedAt ?? .distantPast) }
    }

    // MARK: - Data

    private func loadData() {
        let accessToken: String
        let accountEmail: String

        if TestDataProvider.isUITesting {
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
                let fetched = try await LinearAPI.shared.fetchTouchedIssues(
                    accessToken: accessToken,
                    accountEmail: accountEmail,
                    since: scope.sinceDuration
                )
                await MainActor.run {
                    items = fetched
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

// MARK: - Row

private struct RecentRow: View {
    let issue: Issue

    @Environment(\.theme) private var theme
    @State private var isHovered = false

    var body: some View {
        Button(action: openInLinear) {
            HStack(spacing: 10) {
                IssueStateCircle(state: issue.state)
                Text(issue.identifier)
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(theme.primary)
                    .frame(width: 70, alignment: .leading)
                Text(issue.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(theme.foreground)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
                trailing
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Rectangle().fill(isHovered ? theme.cardInset : Color.clear))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }

    private var trailing: some View {
        HStack(spacing: 5) {
            Text(actorInitials)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(theme.muted)
            Text(RelativeTimeFormatter.shortLabel(for: issue.updatedAt ?? Date()))
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(theme.tertiary)
        }
        .fixedSize()
    }

    private var actorInitials: String {
        guard let name = issue.assignee?.name else { return "—" }
        let parts = name.split(separator: " ").prefix(2)
        let letters = parts.compactMap { $0.first }.map { String($0) }
        return letters.joined().uppercased()
    }

    private func openInLinear() {
        if let url = URL(string: issue.url) {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - Scope chip

private struct ScopeChip: View {
    @Binding var scope: RecentView.Scope
    @Environment(\.theme) private var theme

    var body: some View {
        Menu {
            ForEach(RecentView.Scope.allCases) { option in
                Button(action: { scope = option }) {
                    HStack {
                        Text(option.label)
                        if scope == option {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 5) {
                Text("Scope:")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(theme.tertiary)
                Text(scope.label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(theme.muted)
                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(theme.tertiary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
    }
}
