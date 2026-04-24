import SwiftUI

/// The Mine tab. Flat list of issues the viewer is on the hook for,
/// filterable by the role the viewer plays: created by them, assigned to
/// them (their work to ship), or the union of both. See Paper artboard
/// "Popover - My Issues".
struct MyIssuesView: View {
    @State private var assignedIssues: [Issue] = []
    @State private var createdIssues: [Issue] = []
    @State private var openIssues: [Issue] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var hasLoadedOnce = false
    @State private var mode: MineMode = .all
    @State private var loadTask: Task<Void, Never>?

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
                        subtitle: emptySubtitle
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
        .onChange(of: mode) { _, _ in rebuildOpen() }
        .onReceive(NotificationCenter.default.publisher(for: .teamFilterChanged)) { _ in
            rebuildOpen()
        }
        .onReceive(NotificationCenter.default.publisher(for: .refreshAllData)) { _ in
            loadData()
        }
    }

    // MARK: - Sub-header

    private var subHeader: some View {
        HStack(spacing: 8) {
            PopoverTeamChip()
            PopoverChip(
                prefix: "Show:",
                selection: $mode,
                options: MineMode.allCases,
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

    private var emptySubtitle: String {
        switch mode {
        case .all:      return "Issues you own or created will show up here."
        case .assigned: return "Issues assigned to you will show up here."
        case .created:  return "Issues you created will show up here."
        }
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
        let source: [Issue]
        switch mode {
        case .all:
            // Dedupe on id — an issue I both created and am assigned to
            // would otherwise appear twice.
            var byId: [String: Issue] = [:]
            for issue in assignedIssues + createdIssues { byId[issue.id] = issue }
            source = Array(byId.values)
        case .assigned:
            source = assignedIssues
        case .created:
            source = createdIssues
        }

        let selectedTeam = AppSettings.shared.selectedTeamId
        let filtered = source.filter { issue in
            guard issue.state?.isOpen ?? true else { return false }
            if let selectedTeam { return issue.team?.id == selectedTeam }
            return true
        }

        openIssues = filtered.sorted { lhs, rhs in
            // "Created" mode sorts by created date (newest first) because
            // that's the metric the user is eyeing. Everything else sorts
            // by updated to keep fresh activity on top.
            let key: (Issue) -> Date? = mode == .created ? { $0.createdAt } : { $0.updatedAt }
            return (key(lhs) ?? .distantPast) > (key(rhs) ?? .distantPast)
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

        // Cancel any in-flight fetch so a rapid refresh doesn't leave
        // two requests racing to stamp state.
        loadTask?.cancel()

        loadTask = Task {
            do {
                // Single GraphQL operation returns both assigned and created
                // connections. The Show chip pivots over these two lists
                // client-side — no re-fetch on toggle.
                let bundle = try await LinearAPI.shared.fetchMineIssues(
                    accessToken: session.accessToken,
                    accountEmail: session.accountEmail
                )
                if Task.isCancelled { return }
                await MainActor.run {
                    assignedIssues = bundle.assigned
                    createdIssues = bundle.created
                    rebuildOpen()
                    isLoading = false
                }
            } catch {
                if Task.isCancelled { return }
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }

    enum MineMode: String, CaseIterable, Identifiable {
        case all, assigned, created

        var id: String { rawValue }
        var label: String {
            switch self {
            case .all:      return "All"
            case .assigned: return "Assigned"
            case .created:  return "Created"
            }
        }
    }
}
