import SwiftUI

/// Placeholder shown inside any tab when no Linear account is connected.
/// Kept for API stability; delegates to StatePlaceholderView.
struct NoAccountView: View {
    let message: String

    init(message: String = "Connect your Linear account to get started.") {
        self.message = message
    }

    var body: some View {
        StatePlaceholderView(
            systemImage: "person.crop.circle.badge.plus",
            title: "No Linear account",
            subtitle: message
        ) {
            AppSecondaryButton(
                title: "Open Settings",
                systemImage: "gearshape",
                tint: .primary,
                action: openSettings
            )
            .padding(.top, 4)
        }
    }

    private func openSettings() {
        NotificationCenter.default.post(name: .settingsRequested, object: nil)
    }
}
