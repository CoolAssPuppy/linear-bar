import SwiftUI

/// A reusable view shown when no Linear account is connected
struct NoAccountView: View {
    let message: String

    init(message: String = "Connect your Linear account to get started.") {
        self.message = message
    }

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No Linear account")
                .font(.headline)

            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button(action: openSettings) {
                HStack(spacing: 6) {
                    Image(systemName: "gearshape")
                    Text("Open Settings")
                }
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .padding()
    }

    private func openSettings() {
        NotificationCenter.default.post(name: .settingsRequested, object: nil)
    }
}
