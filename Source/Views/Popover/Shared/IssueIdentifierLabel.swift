import SwiftUI
import AppKit

/// Monospaced Linear issue identifier (e.g. `DEBR-265`) with a
/// hover-revealed "copy link" affordance. When the containing row is
/// hovered *and* `url` is non-nil, a small link glyph fades in to the
/// right of the text. Clicking the glyph copies the issue URL to the
/// pasteboard and pops a "Link copied!" toast — without triggering the
/// outer row's open-in-Linear action.
///
/// Pass `rowIsHovered` from the parent row's own hover state so the
/// affordance tracks row-level hover rather than only the narrow text.
struct IssueIdentifierLabel: View {
    let identifier: String
    let url: String?
    let rowIsHovered: Bool
    /// When non-nil, the label reserves a fixed width (used by list rows
    /// where identifier columns are aligned). When nil, the label sizes to
    /// its content (used by InboxView's wrapping metadata line).
    let width: CGFloat?

    @Environment(\.theme) private var theme
    @State private var iconHovered = false

    init(identifier: String,
         url: String?,
         rowIsHovered: Bool,
         width: CGFloat? = 70) {
        self.identifier = identifier
        self.url = url
        self.rowIsHovered = rowIsHovered
        self.width = width
    }

    var body: some View {
        HStack(spacing: 4) {
            Text(identifier)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(theme.primary)

            if showsCopyIcon {
                Button(action: copyLink) {
                    Image(systemName: "link")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(iconHovered ? theme.primary : theme.muted)
                        .padding(2)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .onHover { iconHovered = $0 }
                .help("Copy link to \(identifier)")
                .transition(.opacity)
            }

            if width != nil {
                Spacer(minLength: 0)
            }
        }
        .frame(width: width, alignment: .leading)
        .animation(.easeOut(duration: 0.12), value: rowIsHovered)
    }

    private var showsCopyIcon: Bool {
        rowIsHovered && url != nil
    }

    private func copyLink() {
        guard let url else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(url, forType: .string)
        ToastCenter.shared.show("Link copied!")
    }
}
