import SwiftUI

/// Main popover view with tab navigation
struct MenuBarView: View {
    @State private var selectedTab: Tab = .favorites
    @State private var isRefreshing = false

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
        HStack(spacing: 12) {
            // App icon with glow
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.accentColor.opacity(0.2),
                                Color.purple.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)
                    .blur(radius: 8)

                if let appIcon = NSImage(named: NSImage.applicationIconName) {
                    Image(nsImage: appIcon)
                        .resizable()
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                }
            }

            Text("IssueBar")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            Spacer()

            // Create new item menu with styled button
            Menu {
                Button {
                    openLinearCreate(type: "issue")
                } label: {
                    Label("New Issue", systemImage: "checkmark.circle")
                }
                Button {
                    openLinearCreate(type: "project")
                } label: {
                    Label("New Project", systemImage: "folder")
                }
                Button {
                    openLinearCreate(type: "initiative")
                } label: {
                    Label("New Initiative", systemImage: "target")
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.green, .mint],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Text("Add New")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(.regularMaterial)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(Color.green.opacity(0.3), lineWidth: 1)
                )
            }
            .menuStyle(.borderlessButton)
            .help("Create New...")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            .regularMaterial,
            in: RoundedRectangle(cornerRadius: 0)
        )
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
        HStack(spacing: 10) {
            // Refresh button with animation
            refreshButton

            Spacer()

            // Settings button
            footerButton(
                icon: "gearshape.fill",
                title: "Settings",
                gradient: [.blue, .cyan]
            ) {
                openSettings()
            }

            // Quit button
            footerButton(
                icon: "power",
                title: "Quit",
                gradient: [.red, .orange]
            ) {
                quitApp()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            .regularMaterial,
            in: RoundedRectangle(cornerRadius: 0)
        )
    }

    private var refreshButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                isRefreshing = true
            }
            Task {
                refreshAllViews()
                try? await Task.sleep(nanoseconds: 500_000_000)
                withAnimation {
                    isRefreshing = false
                }
            }
        }) {
            ZStack {
                Circle()
                    .fill(.regularMaterial)
                    .frame(width: 32, height: 32)

                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .rotationEffect(.degrees(isRefreshing ? 360 : 0))
            }
            .overlay(
                Circle()
                    .strokeBorder(Color.blue.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .help("Refresh all data")
    }

    private func footerButton(icon: String, title: String, gradient: [Color], action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.thinMaterial)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func openSettings() {
        NotificationCenter.default.post(name: .settingsRequested, object: nil)
    }

    private func openLinearCreate(type: String) {
        // Get the organization slug and team key from settings
        guard let orgSlug = AppSettings.shared.accounts.first(where: { $0.isEnabled && $0.authStatus == .valid })?.organizationSlug else {
            return
        }

        let teamKey = AppSettings.shared.selectedTeamKey

        var url: URL?

        switch type {
        case "issue":
            // Linear's new issue URL with team if available
            if let teamKey = teamKey {
                url = URL(string: "https://linear.app/\(orgSlug)/team/\(teamKey)/new")
            } else {
                url = URL(string: "https://linear.app/\(orgSlug)/issue/new")
            }
        case "project":
            // Linear's new project URL
            url = URL(string: "https://linear.app/\(orgSlug)/projects/new")
        case "initiative":
            // Linear's new initiative URL (roadmap item)
            url = URL(string: "https://linear.app/\(orgSlug)/roadmap")
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
