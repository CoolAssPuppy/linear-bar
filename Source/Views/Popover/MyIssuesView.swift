import SwiftUI

/// The Mine tab. Flat list of issues assigned to the viewer, sorted by
/// updated or created date. Drops priority grouping, tags, comment counts,
/// and avatars per the simplification brief — each row is status + ID +
/// title + one trailing signal (due date or SLA). See Paper artboard
/// "Popover - My Issues".
struct MyIssuesView: View {
    @State private var issues: [Issue] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var hasLoadedOnce = false
    @State private var sortMode: MineSort = .updated

    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 0) {
            subHeader

            Group {
                if isLoading && issues.isEmpty {
                    LoadingStateView("Loading your issues…")
                } else if AppSettings.shared.accounts.isEmpty {
                    NoAccountView(message: "Connect your Linear account to see your issues.")
                } else if let error = errorMessage {
                    ErrorStateView(title: "Could not load issues", message: error, onRetry: loadData)
                } else if sortedIssues.isEmpty {
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
        .onReceive(NotificationCenter.default.publisher(for: .refreshAllData)) { _ in
            loadData()
        }
    }

    // MARK: - Sub-header

    private var subHeader: some View {
        HStack(spacing: 8) {
            PopoverTeamChip()
            SortChip(mode: $sortMode)
            Spacer(minLength: 0)
            Text(openLabel)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(theme.tertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var openLabel: String {
        let count = sortedIssues.count
        if count == 1 { return "1 open" }
        return "\(count) open"
    }

    // MARK: - Content

    private var sortedIssues: [Issue] {
        let open = issues.filter { ($0.state?.type ?? "") != "completed" && ($0.state?.type ?? "") != "canceled" }
        switch sortMode {
        case .updated:
            return open.sorted { ($0.updatedAt ?? .distantPast) > ($1.updatedAt ?? .distantPast) }
        case .created:
            return open.sorted { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
        }
    }

    private var contentView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(sortedIssues) { issue in
                    CompactIssueRow(issue: issue)
                }
            }
            .padding(.bottom, 8)
        }
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
                let fetched = try await LinearAPI.shared.fetchAssignedIssues(
                    accessToken: accessToken,
                    accountEmail: accountEmail
                )
                await MainActor.run {
                    issues = fetched
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

// MARK: - Row

/// Compact issue row used by Mine, Pulse, and Recent. Keeps a fixed 66pt
/// column for the monospaced issue ID so rows align across the popover.
struct CompactIssueRow: View {
    let identifier: String
    let title: String
    let url: String
    let state: IssueState?
    let trailing: IssueTrailing

    @Environment(\.theme) private var theme
    @State private var isHovered = false

    init(identifier: String,
         title: String,
         url: String,
         state: IssueState?,
         trailing: IssueTrailing = .none) {
        self.identifier = identifier
        self.title = title
        self.url = url
        self.state = state
        self.trailing = trailing
    }

    init(issue: Issue) {
        self.identifier = issue.identifier
        self.title = issue.title
        self.url = issue.url
        self.state = issue.state
        self.trailing = Self.trailing(for: issue)
    }

    init(cycleIssue: CycleIssue) {
        self.identifier = cycleIssue.identifier
        self.title = cycleIssue.title
        self.url = cycleIssue.url
        self.state = cycleIssue.state
        let reason = cycleIssue.riskReason
        self.trailing = .riskReason(label: reason.label, isCritical: reason.isCritical)
    }

    var body: some View {
        Button(action: openInLinear) {
            HStack(spacing: 10) {
                IssueStateCircle(state: state)
                Text(identifier)
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(theme.primary)
                    .frame(width: 70, alignment: .leading)
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(theme.foreground)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
                trailingLabel
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Rectangle().fill(isHovered ? theme.cardInset : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }

    @ViewBuilder
    private var trailingLabel: some View {
        switch trailing {
        case .none:
            EmptyView()
        case .due(let label, let isOverdue):
            Text(label)
                .font(.system(size: 10, weight: isOverdue ? .semibold : .medium))
                .foregroundStyle(isOverdue ? theme.destructive : theme.muted)
                .fixedSize()
        case .riskReason(let label, let isCritical):
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(isCritical ? theme.destructive : theme.warning)
                .fixedSize()
        case .stateLabel(let label):
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(theme.primary)
                .fixedSize()
        }
    }

    private func openInLinear() {
        if let target = URL(string: url) {
            NSWorkspace.shared.open(target)
        }
    }

    /// Translates an Issue's SLA/due/review metadata into the single trailing
    /// signal the row displays. SLA wins over due date which wins over the
    /// "In Review" badge, which wins over nothing.
    private static func trailing(for issue: Issue) -> IssueTrailing {
        if let dueDate = issue.dueDate {
            return .due(label: dueLabel(from: dueDate), isOverdue: issue.isOverdue)
        }
        if issue.state?.name.lowercased() == "in review" || issue.state?.name.lowercased() == "review" {
            return .stateLabel(label: "In Review")
        }
        return .none
    }

    private static func dueLabel(from iso: String) -> String {
        guard let date = ISO8601DateFormatter().date(from: iso + "T00:00:00Z") else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "Due \(formatter.string(from: date))"
    }
}

enum IssueTrailing {
    case none
    case due(label: String, isOverdue: Bool)
    case riskReason(label: String, isCritical: Bool)
    case stateLabel(label: String)
}

// MARK: - State circle

/// Linear-style state circle: dashed for backlog, empty for todo, amber
/// half-fill for started, blue 3/4 fill for in-review, green solid for
/// completed, grey dotted slash for canceled. Matches the Paper iconography.
struct IssueStateCircle: View {
    let state: IssueState?

    var body: some View {
        ZStack {
            base
        }
        .frame(width: 14, height: 14)
    }

    @ViewBuilder
    private var base: some View {
        switch classify(state) {
        case .backlog:
            Circle()
                .strokeBorder(Color(hex: "#3D3F4E"), style: StrokeStyle(lineWidth: 1.4, dash: [1.8, 1.8]))
        case .unstarted:
            Circle()
                .strokeBorder(Color(hex: "#3D3F4E"), lineWidth: 1.4)
        case .started:
            partialFilledCircle(color: Color(hex: "#E6B35A"), fraction: 0.5)
        case .review:
            partialFilledCircle(color: Color(hex: "#7B8BDE"), fraction: 0.75)
        case .blocked:
            Circle()
                .strokeBorder(Color(hex: "#EB5757"), lineWidth: 1.4)
        case .completed:
            ZStack {
                Circle().fill(Color(hex: "#27AE60"))
                Image(systemName: "checkmark")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundStyle(Color.white)
            }
        case .canceled:
            ZStack {
                Circle().strokeBorder(Color(hex: "#5E6076"), lineWidth: 1.4)
                Image(systemName: "xmark")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundStyle(Color(hex: "#5E6076"))
            }
        }
    }

    private func partialFilledCircle(color: Color, fraction: CGFloat) -> some View {
        ZStack {
            Circle().strokeBorder(color, lineWidth: 1.4)
            Circle()
                .trim(from: 0, to: fraction)
                .fill(color)
                .rotationEffect(.degrees(-90))
                .scaleEffect(0.55)
        }
    }

    private enum StateKind { case backlog, unstarted, started, review, blocked, completed, canceled }

    private func classify(_ state: IssueState?) -> StateKind {
        let name = (state?.name ?? "").lowercased()
        let type = (state?.type ?? "").lowercased()
        if name == "blocked" { return .blocked }
        if name.contains("review") { return .review }
        switch type {
        case "backlog", "triage": return .backlog
        case "started":           return .started
        case "completed":         return .completed
        case "canceled":          return .canceled
        default:                  return .unstarted
        }
    }
}

// MARK: - Chip components

/// Drop-down chip used consistently across popover tabs. Currently the menu
/// is a placeholder; the team filter will be wired to `selectedTeamId`
/// workspace-wide in a later commit.
struct PopoverTeamChip: View {
    @Environment(\.theme) private var theme
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 5) {
            Text("All teams")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(theme.muted)
            Image(systemName: "chevron.down")
                .font(.system(size: 8, weight: .semibold))
                .foregroundStyle(theme.tertiary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(isHovered ? theme.cardInset : Color.clear)
        )
        .onHover { isHovered = $0 }
    }
}

private struct SortChip: View {
    @Binding var mode: MyIssuesView.MineSort
    @Environment(\.theme) private var theme

    var body: some View {
        Menu {
            ForEach(MyIssuesView.MineSort.allCases) { option in
                Button(action: { mode = option }) {
                    HStack {
                        Text(option.label)
                        if mode == option {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 5) {
                Text("Sort:")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(theme.tertiary)
                Text(mode.label)
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
