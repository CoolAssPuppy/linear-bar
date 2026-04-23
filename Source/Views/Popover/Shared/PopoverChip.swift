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

/// Placeholder team chip shown when the tab doesn't yet support filtering by
/// team. Renders "All teams" with a chevron and no menu. Kept distinct from
/// `PopoverChip` so the hover affordance matches the other tabs' chips
/// without pretending there's an actionable menu behind it.
struct PopoverTeamPlaceholder: View {
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
