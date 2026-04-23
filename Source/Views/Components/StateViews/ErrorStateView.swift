import SwiftUI

/// A reusable error state view with an icon, title, message, and retry button
struct ErrorStateView: View {
    let title: String
    let message: String
    let onRetry: () -> Void

    @Environment(\.theme) private var theme

    init(title: String = "Error", message: String, onRetry: @escaping () -> Void) {
        self.title = title
        self.message = message
        self.onRetry = onRetry
    }

    var body: some View {
        VStack(spacing: 12) {
            Spacer()

            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(theme.destructive.opacity(0.1))
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 22, weight: .light))
                    .foregroundStyle(theme.destructive)
            }
            .frame(width: 56, height: 56)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(theme.destructive.opacity(0.3), lineWidth: 1)
            )

            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(theme.foreground)

                Text(message)
                    .font(.system(size: 11))
                    .foregroundStyle(theme.muted)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 260)
            }

            AppSecondaryButton(title: "Retry", systemImage: "arrow.clockwise", tint: .primary, action: onRetry)
                .padding(.top, 4)

            Spacer()
        }
        .padding()
    }
}
