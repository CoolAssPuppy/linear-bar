import SwiftUI

/// A reusable error state view with an icon, title, message, and retry button
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
        VStack(spacing: 12) {
            Spacer()

            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            Text(title)
                .font(.headline)

            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Retry", action: onRetry)
                .buttonStyle(.borderedProminent)

            Spacer()
        }
        .padding()
    }
}
