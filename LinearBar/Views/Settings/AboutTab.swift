import SwiftUI

/// About tab displaying app information and version
struct AboutTab: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.square.fill")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)

            Text("LinearBar")
                .font(.title)
                .fontWeight(.bold)

            Text("Quick access to Linear from your menu bar")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 8) {
                Text("Version 1.0.0")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("Build 1")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Link("View on GitHub", destination: URL(string: "https://github.com")!)
                .font(.caption)
        }
        .padding(40)
    }
}
