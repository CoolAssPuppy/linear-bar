import SwiftUI

/// Chip-style menu button shared across popover tabs. Used for the team
/// filter, sort picker, scope picker, and team scope in Pulse. Consolidates
/// what were four near-identical implementations into a single component
/// parameterized by its options list, selected value, and optional prefix.
///
/// The chip renders its label + chevron inside an invisible tap target; on
/// hover it gets a subtle inset background. The attached SwiftUI Menu handles
/// the dropdown list.
struct PopoverChip<Option: Hashable>: View {
    /// Optional prefix (e.g. "Sort:") drawn in `theme.tertiary` before the
    /// selected option label. Pass nil for chips that don't need one.
    let prefix: String?

    /// Currently selected value. Rendered via `label(for:)`.
    @Binding var selection: Option

    /// Ordered options the menu presents.
    let options: [Option]

    /// Renders the display label for an option. Shown both in the chip body
    /// and the menu items.
    let label: (Option) -> String

    /// Tint of the selected label. Defaults to `theme.muted`; Pulse overrides
    /// it with `theme.foreground` to make the scoped team read as primary.
    var selectionWeight: SelectionWeight = .muted

    @Environment(\.theme) private var theme

    enum SelectionWeight {
        case muted
        case foreground
    }

    var body: some View {
        Menu {
            ForEach(options, id: \.self) { option in
                Button(action: { selection = option }) {
                    HStack {
                        Text(label(option))
                        if option == selection {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 5) {
                if let prefix {
                    Text(prefix)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(theme.tertiary)
                }
                Text(label(selection))
                    .font(.system(size: 11, weight: selectionWeight == .foreground ? .semibold : .medium))
                    .foregroundStyle(selectionWeight == .foreground ? theme.foreground : theme.muted)
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

/// Shared team filter chip. Backed by `TeamsStore`; writes the selection to
/// `AppSettings.selectedTeamId` (nil = "All teams"). Every popover tab
/// reads the same settings value so selecting a team in one tab scopes
/// every other tab too.
struct PopoverTeamChip: View {
    @ObservedObject private var teams = TeamsStore.shared
    @ObservedObject private var settings = AppSettings.shared
    @Environment(\.theme) private var theme

    var body: some View {
        Menu {
            Button(action: { select(nil) }) {
                HStack {
                    Text("All teams")
                    if settings.selectedTeamId == nil {
                        Image(systemName: "checkmark")
                    }
                }
            }

            if !teams.teams.isEmpty {
                Divider()
                ForEach(teams.teams) { team in
                    Button(action: { select(team) }) {
                        HStack {
                            Text(team.name)
                            if settings.selectedTeamId == team.id {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 5) {
                Text(currentLabel)
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
        .onAppear { teams.loadIfNeeded() }
    }

    private var currentLabel: String {
        guard let id = settings.selectedTeamId else { return "All teams" }
        return teams.teams.first(where: { $0.id == id })?.name ?? "All teams"
    }

    private func select(_ team: Team?) {
        settings.selectedTeamId = team?.id
        settings.selectedTeamKey = team?.key
        NotificationCenter.default.post(name: .teamFilterChanged, object: nil)
    }
}
