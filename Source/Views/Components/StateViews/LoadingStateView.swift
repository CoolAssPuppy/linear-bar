import SwiftUI

/// A reusable loading state view with a spinner and message
struct LoadingStateView: View {
    let message: String

    @Environment(\.theme) private var theme

    init(_ message: String = "Loading...") {
        self.message = message
    }

    var body: some View {
        VStack {
            Spacer()
            ProgressView()
                .controlSize(.regular)
                .tint(theme.primary)
            Text(message)
                .font(.system(size: 12))
                .foregroundStyle(theme.muted)
                .padding(.top, 8)
            Spacer()
        }
    }
}
