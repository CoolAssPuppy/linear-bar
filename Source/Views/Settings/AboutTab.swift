import SwiftUI

/// About tab displaying app information and version
struct AboutTab: View {
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [theme.primary, theme.primaryDeep],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Image(systemName: "checkmark.square.fill")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 72, height: 72)

            Text("Linear Bar")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(theme.foreground)

            Text("Quick access to Linear from your menu bar")
                .font(.system(size: 11))
                .foregroundStyle(theme.muted)
                .multilineTextAlignment(.center)

            Text("Version \(appVersion) (\(buildNumber))")
                .font(.system(size: 11))
                .foregroundStyle(theme.tertiary)

            Spacer()

            Link("View on GitHub", destination: URL(string: "https://github.com")!)
                .font(.system(size: 11))
                .foregroundStyle(theme.primary)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.background)
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
    }

    private var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
    }
}
