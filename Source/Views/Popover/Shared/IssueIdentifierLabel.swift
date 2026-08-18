import SwiftUI

/// Monospaced Linear issue identifier (for example, `DEBR-265`).
struct IssueIdentifierLabel: View {
    let identifier: String
    /// When non-nil, the label reserves a fixed width (used by list
    /// rows where identifier columns are aligned). When nil, the
    /// label sizes to its content (used by InboxView's wrapping
    /// metadata line).
    let width: CGFloat?

    @Environment(\.theme) private var theme

    init(identifier: String,
         width: CGFloat? = 70) {
        self.identifier = identifier
        self.width = width
    }

    var body: some View {
        Text(identifier)
            .font(.system(size: 10, weight: .semibold, design: .monospaced))
            .foregroundStyle(theme.primary)
            .frame(width: width, alignment: .leading)
    }
}
