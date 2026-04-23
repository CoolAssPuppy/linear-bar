import SwiftUI

/// Error placeholder with a Retry button. Kept for API stability at call
/// sites; delegates to StatePlaceholderView.
struct ErrorStateView: View {
    let title: String
    let message: String
    let onRetry: () -> Void

    init(title: String = "Error", message: String, onRetry: @escaping () -> Void) {
        self.title = title
        self.message = message
        self.onRetry = onRetry
    }

    var body: some View {
        StatePlaceholderView(
            systemImage: "exclamationmark.triangle.fill",
            title: title,
            subtitle: message,
            tint: .destructive
        ) {
            AppSecondaryButton(
                title: "Retry",
                systemImage: "arrow.clockwise",
                tint: .primary,
                action: onRetry
            )
            .padding(.top, 4)
        }
    }
}
