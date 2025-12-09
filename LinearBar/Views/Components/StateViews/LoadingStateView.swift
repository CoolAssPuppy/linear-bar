import SwiftUI

/// A reusable loading state view with a spinner and message
struct LoadingStateView: View {
    let message: String

    init(_ message: String = "Loading...") {
        self.message = message
    }

    var body: some View {
        VStack {
            Spacer()
            ProgressView()
                .controlSize(.large)
            Text(message)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .padding(.top, 8)
            Spacer()
        }
    }
}
