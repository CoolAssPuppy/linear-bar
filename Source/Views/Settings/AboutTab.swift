import SwiftUI

/// About tab displaying app information and version
struct AboutTab: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.square.fill")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)

            Text("IssueBar")
                .font(.title)
                .fontWeight(.bold)

            Text("Quick access to Linear from your menu bar")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Text("Version \(appVersion) (\(buildNumber))")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            Link("View on GitHub", destination: URL(string: "https://github.com")!)
                .font(.caption)
        }
        .padding(40)
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
    }

    private var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
    }
}
