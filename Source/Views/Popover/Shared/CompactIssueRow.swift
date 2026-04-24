import SwiftUI

/// Shared row used by Mine, Recent, Pulse, and Search result rows. Renders
/// an issue state circle + ID + title + an optional trailing signal.
///
/// Three convenience initializers cover the cases that actually appear in
/// the popover today:
/// - `init(issue:)`         — Mine tab (due/review).
/// - `init(cycleIssue:)`    — Pulse tab (risk reason).
/// - `init(recentIssue:)`   — Recent tab (actor initials + relative time).
///
/// The generic `init(identifier:...)` is kept for surfaces that don't have
/// a full Issue value but still want the same visual density.
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
        self.init(
            identifier: issue.identifier,
            title: issue.title,
            url: issue.url,
            state: issue.state,
            trailing: Self.defaultTrailing(for: issue)
        )
    }

    init(cycleIssue: CycleIssue) {
        let reason = cycleIssue.riskReason
        self.init(
            identifier: cycleIssue.identifier,
            title: cycleIssue.title,
            url: cycleIssue.url,
            state: cycleIssue.state,
            trailing: .riskReason(label: reason.label, isCritical: reason.isCritical)
        )
    }

    init(recentIssue issue: Issue) {
        self.init(
            identifier: issue.identifier,
            title: issue.title,
            url: issue.url,
            state: issue.state,
            trailing: .actorAndTime(
                initials: PersonName.initials(from: issue.assignee?.name),
                relative: RelativeTimeFormatter.shortLabel(for: issue.updatedAt ?? Date())
            )
        )
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
            .background(Rectangle().fill(isHovered ? theme.cardInset : Color.clear))
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
        case .actorAndTime(let initials, let relative):
            HStack(spacing: 5) {
                Text(initials)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(theme.muted)
                Text(relative)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(theme.tertiary)
            }
            .fixedSize()
        }
    }

    private func openInLinear() {
        _ = SafeExternalURL.openLinearURL(from: url)
    }

    /// Translates an Issue's SLA/due/review metadata into the single trailing
    /// signal the row shows. SLA would take precedence if SLA metadata were
    /// embedded in Issue; until then we surface due date first, then the
    /// "In Review" badge.
    private static func defaultTrailing(for issue: Issue) -> IssueTrailing {
        if let dueDate = issue.dueDate, let label = dueLabel(from: dueDate) {
            return .due(label: label, isOverdue: issue.isOverdue)
        }
        let name = (issue.state?.name ?? "").lowercased()
        if name.contains("review") {
            return .stateLabel(label: "In Review")
        }
        return .none
    }

    private static func dueLabel(from iso: String) -> String? {
        guard let date = Self.iso8601DateParser.date(from: iso + "T00:00:00Z") else { return nil }
        return "Due \(Self.dueDateFormatter.string(from: date))"
    }

    // Single shared formatter for all rows; instantiating one per row is
    // surprisingly heavy (10s of microseconds).
    private static let iso8601DateParser: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        return formatter
    }()

    private static let dueDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()
}

/// Trailing slot variants a row can render. New cases land here rather than
/// adding overloads on `CompactIssueRow`.
enum IssueTrailing {
    case none
    case due(label: String, isOverdue: Bool)
    case riskReason(label: String, isCritical: Bool)
    case stateLabel(label: String)
    case actorAndTime(initials: String, relative: String)
}

/// Small helper for "first letter of first two words" initial extraction.
/// Shared between notification avatars and recent-row trailing.
enum PersonName {
    static func initials(from name: String?) -> String {
        guard let name, !name.isEmpty else { return "—" }
        let parts = name.split(separator: " ").prefix(2)
        let letters = parts.compactMap { $0.first }.map { String($0) }
        return letters.joined().uppercased()
    }
}
