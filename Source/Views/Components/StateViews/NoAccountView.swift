import SwiftUI

/// A reusable view shown when no Linear account is connected
struct NoAccountView: View {
    let message: String

    @Environment(\.theme) private var theme

    init(message: String = "Connect your Linear account to get started.") {
        self.message = message
    }

    var body: some View {
        VStack(spacing: 14) {
            Spacer()

            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(theme.card)
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.system(size: 22, weight: .light))
                    .foregroundStyle(theme.muted)
            }
            .frame(width: 56, height: 56)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(theme.border, lineWidth: 1)
            )

            VStack(spacing: 4) {
                Text("No Linear account")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(theme.foreground)

                Text(message)
                    .font(.system(size: 11))
                    .foregroundStyle(theme.muted)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 260)
            }

            AppSecondaryButton(title: "Open Settings", systemImage: "gearshape", tint: .primary, action: openSettings)
                .padding(.top, 4)

            Spacer()
        }
        .padding()
    }

    private func openSettings() {
        NotificationCenter.default.post(name: .settingsRequested, object: nil)
    }
}
