import SwiftUI

/// Main popover view with tab navigation
struct MenuBarView: View {
    @State private var selectedTab: Tab = .favorites

    var body: some View {
        VStack(spacing: 0) {
            headerBar

            Divider()

            tabBar

            Divider()

            contentArea

            Divider()

            footerBar
        }
        .frame(width: 400, height: 500)
        .background(.ultraThinMaterial)
        .onAppear {
            loadDefaultTab()
        }
    }

    private func loadDefaultTab() {
        let defaultTab = AppSettings.shared.defaultTab
        switch defaultTab {
        case .favorites:
            selectedTab = .favorites
        case .recent:
            selectedTab = .recent
        case .search:
            selectedTab = .search
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            Text("LinearBar")
                .font(.headline)

            Spacer()

            // Create new item menu
            Menu {
                Button(action: { openLinearCreate(type: "issue") }) {
                    Label("New Issue", systemImage: "checkmark.circle")
                }
                Button(action: { openLinearCreate(type: "project") }) {
                    Label("New Project", systemImage: "folder")
                }
                Button(action: { openLinearCreate(type: "initiative") }) {
                    Label("New Initiative", systemImage: "target")
                }
            } label: {
                Image(systemName: "plus.circle")
                    .font(.system(size: 16))
            }
            .menuStyle(.borderlessButton)
            .help("Create New...")

            Button(action: openSettings) {
                Image(systemName: "gearshape")
                    .font(.system(size: 16))
            }
            .buttonStyle(.borderless)
            .help("Settings")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(height: 40)
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        HStack(spacing: 0) {
            tabButton(tab: .favorites, icon: "star.fill", title: "Favorites")
            tabButton(tab: .recent, icon: "clock.arrow.circlepath", title: "Recent")
            tabButton(tab: .search, icon: "magnifyingglass", title: "Search")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .frame(height: 44)
    }

    private func tabButton(tab: Tab, icon: String, title: String) -> some View {
        Button(action: { selectedTab = tab }) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(title)
                    .font(.system(size: 12))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(selectedTab == tab ? Color.accentColor.opacity(0.1) : Color.clear)
            .foregroundColor(selectedTab == tab ? .accentColor : .secondary)
            .cornerRadius(6)
        }
        .buttonStyle(.borderless)
    }

    // MARK: - Content Area

    private var contentArea: some View {
        Group {
            switch selectedTab {
            case .favorites:
                FavoritesView()
            case .recent:
                RecentlyUpdatedView()
            case .search:
                SearchView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Footer

    private var footerBar: some View {
        HStack {
            Button(action: refreshAllViews) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 12))
            }
            .buttonStyle(.borderless)
            .help("Refresh all data")

            Spacer()

            Button(action: quitApp) {
                Text("Quit")
                    .font(.system(size: 12))
            }
            .buttonStyle(.borderless)
            .help("Quit LinearBar")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .frame(height: 32)
    }

    // MARK: - Actions

    private func openSettings() {
        NotificationCenter.default.post(name: .settingsRequested, object: nil)
    }

    private func openLinearCreate(type: String) {
        // Get the team from the first enabled account's recent team selection
        var url: URL?

        switch type {
        case "issue":
            // Linear's new issue URL - will prompt for team selection if needed
            url = URL(string: "https://linear.app/team/new-issue")
        case "project":
            // Linear's new project URL
            url = URL(string: "https://linear.app/projects/new")
        case "initiative":
            // Linear's new initiative URL (roadmap item)
            url = URL(string: "https://linear.app/roadmap")
        default:
            return
        }

        if let url = url {
            NSWorkspace.shared.open(url)
        }
    }

    private func refreshAllViews() {
        NotificationCenter.default.post(name: .refreshAllData, object: nil)
    }

    private func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    // MARK: - Tab Enum

    enum Tab {
        case favorites
        case recent
        case search
    }
}

struct MenuBarView_Previews: PreviewProvider {
    static var previews: some View {
        MenuBarView()
    }
}
