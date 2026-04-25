import SwiftUI
import AppKit

/// Hover-revealed "copy link" affordance used by column-aligned list
/// rows (Mine, Recent, Search, Faves). Sits in its own fixed-width
/// column so the row's other cells don't reflow when the icon shows.
/// The icon is visible while either the parent row or the icon itself
/// is hovered — the iconHovered branch keeps the icon on screen as
/// the cursor slides off the row body and onto the button.
struct RowCopyLinkButton: View {
    /// URL copied on click. Nil hides the affordance entirely (rows
    /// without an addressable URL still reserve the column gutter).
    let url: String?
    /// Surfaced in the tooltip ("Copy link to DEBR-145").
    let label: String
    /// Driven by the row's own `onHover` so the icon appears together
    /// with the row's hover background.
    let isRowHovered: Bool

    @Environment(\.theme) private var theme
    @State private var iconHovered = false

    /// Reserved column width — large enough for the icon and a small
    /// hit-target halo so rows have a consistent gutter regardless of
    /// hover state.
    static let columnWidth: CGFloat = 22

    var body: some View {
        ZStack {
            if shouldShow {
                Button(action: copy) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(iconHovered ? theme.primary : theme.muted)
                        .frame(width: 18, height: 18)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .onHover { iconHovered = $0 }
                .help("Copy link to \(label)")
                .transition(.opacity)
            }
        }
        .frame(width: Self.columnWidth, alignment: .center)
        .animation(.easeOut(duration: 0.12), value: isRowHovered)
        .animation(.easeOut(duration: 0.12), value: iconHovered)
    }

    private var shouldShow: Bool {
        url != nil && (isRowHovered || iconHovered)
    }

    private func copy() {
        guard let url else { return }
        NSPasteboard.copyString(url)
        ToastCenter.shared.show("Link copied!")
    }
}
