import SwiftUI

/// The LABEL — rule — count header used to group rows in Inbox and Pulse.
/// Count is optional — Inbox's Today/Yesterday dividers omit it, Pulse's
/// "Threatening the cycle" divider shows it.
struct PopoverSectionDivider: View {
    let label: String
    var count: Int? = nil

    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: 10) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.8)
                .foregroundStyle(theme.tertiary)
                .fixedSize()

            Rectangle()
                .fill(theme.divider)
                .frame(height: 1)

            if let count {
                Text("\(count)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(theme.tertiary)
                    .fixedSize()
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 6)
    }
}
