import SwiftUI

/// Settings view for managing accounts and preferences
struct SettingsView: View {
    @ObservedObject private var settings = AppSettings.shared
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            headerBar

            Divider()

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
        .background(.ultraThinMaterial)
        .frame(width: 500, height: 600)
    }

    private var headerBar: some View {
        HStack {
            Text("IssueBar Settings")
                .font(.title2)
                .fontWeight(.semibold)

            Spacer()
        }
        .padding()
        .background(.regularMaterial)
    }
}
