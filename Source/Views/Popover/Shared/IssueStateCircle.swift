import SwiftUI

/// Linear-style state circle shown on the left of every issue row in the
/// popover. Six visual treatments distinguish issue state at a glance:
/// dashed for backlog, empty outline for todo/unstarted, amber half-fill for
/// started, blue three-quarter fill for "in review", a red outlined ring for
/// "blocked", green filled checkmark for completed, and an outlined X for
/// canceled.
///
/// This is deliberately separate from `IssueStatusIcon` (the SF-Symbol-based
/// variant used in the legacy ItemRow). The popover design trades emoji for
/// geometry to preserve a tight 14pt row height.
struct IssueStateCircle: View {
    let state: IssueState?

    @Environment(\.theme) private var theme

    var body: some View {
        base.frame(width: 14, height: 14)
    }

    @ViewBuilder
    private var base: some View {
        switch classify(state) {
        case .backlog:
            Circle()
                .strokeBorder(backlogStroke, style: StrokeStyle(lineWidth: 1.4, dash: [1.8, 1.8]))
        case .unstarted:
            Circle()
                .strokeBorder(unstartedStroke, lineWidth: 1.4)
        case .started:
            partialFilledCircle(color: startedTint, fraction: 0.5)
        case .review:
            partialFilledCircle(color: reviewTint, fraction: 0.75)
        case .blocked:
            Circle()
                .strokeBorder(blockedTint, lineWidth: 1.4)
        case .completed:
            ZStack {
                Circle().fill(completedTint)
                Image(systemName: "checkmark")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundStyle(Color.white)
            }
        case .canceled:
            ZStack {
                Circle().strokeBorder(canceledTint, lineWidth: 1.4)
                Image(systemName: "xmark")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundStyle(canceledTint)
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
        if name == "blocked" { return .blocked }
        if name.contains("review") { return .review }

        switch IssueStateType(rawValue: state?.type ?? "") {
        case .backlog, .triage: return .backlog
        case .started:          return .started
        case .completed:        return .completed
        case .canceled:         return .canceled
        case .unstarted, nil:   return .unstarted
        }
    }

    // MARK: - Tint helpers
    //
    // Keep the state colors semantic so themes can override them. Each tint
    // falls back to a hand-tuned Chapel default when the palette hasn't
    // opted in.

    private var backlogStroke: Color    { Color(hex: "#3D3F4E") }
    private var unstartedStroke: Color  { Color(hex: "#3D3F4E") }
    private var startedTint: Color      { Color(hex: "#E6B35A") }
    private var reviewTint: Color       { theme.primary }
    private var blockedTint: Color      { theme.destructive }
    private var completedTint: Color    { theme.success }
    private var canceledTint: Color     { Color(hex: "#5E6076") }
}

/// Typed view of `IssueState.type`. Linear's canonical set is small and
/// mostly stable; decoding once at the boundary keeps consumers away from
/// raw string comparisons.
enum IssueStateType: String {
    case triage
    case backlog
    case unstarted
    case started
    case completed
    case canceled
}

extension IssueState {
    /// Strongly-typed classification of `type`. Returns nil for unknown
    /// values so callers can fall back to treating the state as unstarted.
    var kind: IssueStateType? { IssueStateType(rawValue: type) }

    /// True when the issue is neither completed nor canceled.
    var isOpen: Bool {
        switch kind {
        case .completed, .canceled: return false
        default:                    return true
        }
    }
}
