import SwiftUI
import AppKit

/// Monospaced Linear issue identifier (e.g. `DEBR-265`). By default
/// renders just the label — column-aligned list rows surface the copy
/// affordance via a separate `RowCopyLinkButton` column, which keeps
/// the column widths stable and stops the icon from overlaying the
/// identifier text.
///
/// `showsCopyButton: true` opts back into the legacy hover-revealed
/// copy overlay. Used by Inbox's inline metadata line, where the
/// identifier sits in a wrapping HStack rather than a fixed column
/// and a separate copy column would feel out of place.
struct IssueIdentifierLabel: View {
    let identifier: String
    let url: String?
    /// When non-nil, the label reserves a fixed width (used by list
    /// rows where identifier columns are aligned). When nil, the
    /// label sizes to its content (used by InboxView's wrapping
    /// metadata line).
    let width: CGFloat?
    /// Floats a small "copy link" glyph at the trailing edge while the
    /// identifier is hovered. Off by default — column rows handle copy
    /// with `RowCopyLinkButton` instead.
    let showsCopyButton: Bool

    @Environment(\.theme) private var theme
    @State private var isHovered = false
    @State private var iconHovered = false

    init(identifier: String,
         url: String? = nil,
         width: CGFloat? = 70,
         showsCopyButton: Bool = false) {
        self.identifier = identifier
        self.url = url
        self.width = width
        self.showsCopyButton = showsCopyButton
    }

    var body: some View {
        if showsCopyButton {
            ZStack(alignment: .trailing) {
                label
                if isHovered, url != nil {
                    copyButton
                        .transition(.opacity)
                }
            }
            .contentShape(Rectangle())
            .onHover { isHovered = $0 }
            .animation(.easeOut(duration: 0.12), value: isHovered)
        } else {
            label
        }
    }

    private var label: some View {
        Text(identifier)
            .font(.system(size: 10, weight: .semibold, design: .monospaced))
            .foregroundStyle(theme.primary)
            .frame(width: width, alignment: .leading)
    }

    private var copyButton: some View {
        Button(action: copyLink) {
            Image(systemName: "link")
                .font(.system(size: 7, weight: .semibold))
                .foregroundStyle(iconHovered ? theme.primaryForeground : theme.primary)
                .frame(width: 13, height: 13)
                .background(
                    Circle()
                        .fill(iconHovered ? theme.primary : Color.clear)
                )
                .overlay(
                    Circle().strokeBorder(theme.primary, lineWidth: 1)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { iconHovered = $0 }
        .help("Copy link to \(identifier)")
    }

    private func copyLink() {
        guard let url else { return }
        NSPasteboard.copyString(url)
        ToastCenter.shared.show("Link copied!")
    }
}
