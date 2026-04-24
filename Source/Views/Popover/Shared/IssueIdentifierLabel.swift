import SwiftUI
import AppKit

/// Monospaced Linear issue identifier (e.g. `DEBR-265`) with a
/// hover-revealed "copy link" affordance. Hovering the identifier
/// itself (not the whole row) floats a small link glyph at the
/// trailing edge, z-indexed above the text, so the column width
/// never reflows. Clicking the glyph copies the issue URL to the
/// pasteboard and pops a "Link copied!" toast — without bubbling to
/// the outer row's open-in-Linear action.
struct IssueIdentifierLabel: View {
    let identifier: String
    let url: String?
    /// When non-nil, the label reserves a fixed width (used by list
    /// rows where identifier columns are aligned). When nil, the
    /// label sizes to its content (used by InboxView's wrapping
    /// metadata line).
    let width: CGFloat?

    @Environment(\.theme) private var theme
    @State private var isHovered = false

    init(identifier: String, url: String?, width: CGFloat? = 70) {
        self.identifier = identifier
        self.url = url
        self.width = width
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            Text(identifier)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(theme.primary)
                .frame(width: width, alignment: .leading)

            if isHovered, url != nil {
                copyButton
                    .transition(.opacity)
            }
        }
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .animation(.easeOut(duration: 0.12), value: isHovered)
    }

    private var copyButton: some View {
        Button(action: copyLink) {
            Image(systemName: "link")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(theme.primaryForeground)
                .frame(width: 16, height: 16)
                .background(
                    Circle()
                        .fill(theme.primary)
                        .shadow(color: Color.black.opacity(0.25), radius: 2, y: 1)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("Copy link to \(identifier)")
    }

    private func copyLink() {
        guard let url else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(url, forType: .string)
        ToastCenter.shared.show("Link copied!")
    }
}
