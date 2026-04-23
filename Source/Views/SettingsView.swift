import SwiftUI

/// Settings view for managing accounts and preferences
struct SettingsView: View {
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var themeStore = ThemeStore.shared
    @State private var selectedTab = 0

    var body: some View {
        let theme = themeStore.palette
        return VStack(spacing: 0) {
            headerBar(theme: theme)

            Rectangle()
                .fill(theme.divider)
                .frame(height: 1)

            TabView(selection: $selectedTab) {
                AccountsTab()
                    .tabItem {
                        Label("Accounts", systemImage: "person.crop.circle")
                    }
                    .tag(0)

                PreferencesTab()
                    .tabItem {
                        Label("Setup", systemImage: "gearshape")
                    }
                    .tag(1)
            }
        }
        .background(theme.background)
        .frame(width: AppStyle.Layout.settingsWidth, height: AppStyle.Layout.settingsHeight)
        .environment(\.theme, theme)
        .environment(\.colorScheme, theme.isDark ? .dark : .light)
    }

    private func headerBar(theme: ThemePalette) -> some View {
        HStack {
            Text("Linear Bar Settings")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(theme.foreground)

            Spacer()
        }
        .padding()
        .background(theme.surface)
    }
}
