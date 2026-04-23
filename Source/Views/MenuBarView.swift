import SwiftUI

/// Main popover view with tab navigation
struct MenuBarView: View {
    @State private var selectedTab: Tab = .favorites
    @State private var isRefreshing = false
    @State private var lastRefreshedAt: Date = Date()
    @ObservedObject private var themeStore = ThemeStore.shared

    var body: some View {
        let theme = themeStore.palette
        return VStack(spacing: 0) {
            HeaderBar(lastRefreshedAt: lastRefreshedAt,
                      onCreate: openLinearCreate,
                      onRefresh: triggerRefresh,
                      onSettings: openSettings,
                      isRefreshing: isRefreshing)
            Divider().background(theme.divider)

            tabBar
            Divider().background(theme.divider)

            contentArea
                .background(theme.background)

            Divider().background(theme.divider)
            BottomBar(onRefresh: triggerRefresh,
                      onOpenWindow: openSettings,
                      onSettings: openSettings,
                      onQuit: quitApp)
        }
        .frame(width: 400, height: 500)
        .background(theme.background)
        .environment(\.theme, theme)
        .environment(\.colorScheme, theme.isDark ? .dark : .light)
        .onAppear {
            loadDefaultTab()
        }
        .onReceive(NotificationCenter.default.publisher(for: .refreshAllData)) { _ in
            lastRefreshedAt = Date()
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

    // MARK: - Tab Bar

    private var tabBar: some View {
        HStack(spacing: 0) {
            TabButton(tab: .favorites, icon: "star.fill", title: "Favorites", selectedTab: $selectedTab)
            TabButton(tab: .recent, icon: "clock.arrow.circlepath", title: "Recent", selectedTab: $selectedTab)
            TabButton(tab: .search, icon: "magnifyingglass", title: "Search", selectedTab: $selectedTab)
        }
        .padding(.horizontal, AppSpacing.xl)
        .padding(.vertical, AppSpacing.md)
        .frame(height: 44)
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

    // MARK: - Actions

    private func openSettings() {
        NotificationCenter.default.post(name: .settingsRequested, object: nil)
    }

    private func openLinearCreate(type: String) {
        guard let orgSlug = AppSettings.shared.accounts.first(where: { $0.isEnabled && $0.authStatus == .valid })?.organizationSlug else {
            return
        }

        let teamKey = AppSettings.shared.selectedTeamKey

        var url: URL?

        switch type {
        case "issue":
            if let teamKey = teamKey {
                url = URL(string: "https://linear.app/\(orgSlug)/team/\(teamKey)/new")
            } else {
                url = URL(string: "https://linear.app/\(orgSlug)/issue/new")
            }
        case "project":
            url = URL(string: "https://linear.app/\(orgSlug)/projects/new")
        case "initiative":
            url = URL(string: "https://linear.app/\(orgSlug)/roadmap")
        default:
            return
        }

        if let url = url {
            NSWorkspace.shared.open(url)
        }
    }

    private func triggerRefresh() {
        isRefreshing = true
        lastRefreshedAt = Date()
        NotificationCenter.default.post(name: .refreshAllData, object: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            isRefreshing = false
        }
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

// MARK: - Tab button

private struct TabButton: View {
    let tab: MenuBarView.Tab
    let icon: String
    let title: String
    @Binding var selectedTab: MenuBarView.Tab
    @Environment(\.theme) private var theme
    @State private var isHovered = false

    var body: some View {
        Button(action: { selectedTab = tab }) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .medium))
                Text(title)
                    .font(.system(size: 12, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .foregroundStyle(foregroundColor)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .fill(backgroundFill)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }

    private var isSelected: Bool { selectedTab == tab }

    private var foregroundColor: Color {
        if isSelected { return theme.primary }
        if isHovered { return theme.foreground }
        return theme.muted
    }

    private var backgroundFill: Color {
        if isSelected { return theme.primary.opacity(0.12) }
        if isHovered { return theme.cardElevated }
        return .clear
    }
}

// MARK: - Header Bar

private struct HeaderBar: View {
    let lastRefreshedAt: Date
    let onCreate: (String) -> Void
    let onRefresh: () -> Void
    let onSettings: () -> Void
    let isRefreshing: Bool

    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: 10) {
            BrandMark()

            VStack(alignment: .leading, spacing: 1) {
                Text("Linear Bar")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(theme.foreground)
                HStack(spacing: 6) {
                    Circle()
                        .fill(theme.success)
                        .frame(width: 6, height: 6)
                        .shadow(color: theme.success.opacity(0.5), radius: 4)
                    Text("Synced \(relativeLabel(for: lastRefreshedAt))")
                        .font(.system(size: 10))
                        .foregroundStyle(theme.muted)
                }
            }

            Spacer(minLength: 8)

            Menu {
                Button { onCreate("issue") } label: {
                    Label("New Issue", systemImage: "checkmark.circle")
                }
                Button { onCreate("project") } label: {
                    Label("New Project", systemImage: "folder")
                }
                Button { onCreate("initiative") } label: {
                    Label("New Initiative", systemImage: "target")
                }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(theme.primaryForeground)
                    .frame(width: 28, height: 26)
                    .background(
                        RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                            .fill(theme.primary)
                    )
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
            .help("Create new item")
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, 12)
        .background(theme.surface)
    }

    private func relativeLabel(for date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        if seconds < 60 { return "just now" }
        if seconds < 3600 { return "\(seconds / 60)m ago" }
        if seconds < 86400 { return "\(seconds / 3600)h ago" }
        return "\(seconds / 86400)d ago"
    }
}

private struct BrandMark: View {
    @Environment(\.theme) private var theme

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [theme.primary, theme.primaryDeep],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Image(systemName: "checkmark.square.fill")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(width: 22, height: 22)
    }
}

// MARK: - Bottom Bar

private struct BottomBar: View {
    let onRefresh: () -> Void
    let onOpenWindow: () -> Void
    let onSettings: () -> Void
    let onQuit: () -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: 4) {
            AppIconButton(systemName: "arrow.triangle.2.circlepath",
                          help: "Refresh all data",
                          spinOnTap: true,
                          action: onRefresh)
            AppIconButton(systemName: "macwindow", help: "Open main window", action: onOpenWindow)
            AppIconButton(systemName: "gearshape", help: "Settings (⌘,)", action: onSettings)

            Spacer(minLength: 0)

            ThemeStrip()

            Spacer(minLength: 0)

            AppIconButton(systemName: "power", help: "Quit Linear Bar", action: onQuit)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(theme.surface)
    }
}

// MARK: - Theme Strip

private struct ThemeStrip: View {
    @ObservedObject private var store = ThemeStore.shared
    @Environment(\.theme) private var theme
    @State private var isExpanded = false

    private static let bouncy: Animation = .spring(response: 0.35, dampingFraction: 0.6)
    private static let dotSize: CGFloat = 10

    var body: some View {
        HStack(spacing: isExpanded ? 6 : 0) {
            ForEach(AppTheme.allCases) { option in
                let palette = option.palette
                let isActive = store.current == option
                let show = isExpanded || isActive

                Button {
                    withAnimation(Self.bouncy) {
                        store.current = option
                        isExpanded = false
                    }
                } label: {
                    ZStack {
                        dotFill(for: option, palette: palette)
                        if isActive {
                            Circle()
                                .stroke(theme.foreground.opacity(0.9), lineWidth: 1.5)
                                .padding(-2.5)
                        }
                    }
                    .frame(width: Self.dotSize, height: Self.dotSize)
                    .scaleEffect(show ? 1 : 0.01)
                    .opacity(show ? 1 : 0)
                }
                .buttonStyle(.plain)
                .frame(width: show ? Self.dotSize : 0)
                .clipped()
                .help(option.label)
            }
        }
        .padding(.horizontal, isExpanded ? 9 : 6)
        .padding(.vertical, 5)
        .background(Capsule().fill(theme.card))
        .overlay(Capsule().strokeBorder(theme.border, lineWidth: 1))
        .animation(Self.bouncy, value: isExpanded)
        .onHover { hovering in
            withAnimation(Self.bouncy) {
                isExpanded = hovering
            }
        }
    }

    @ViewBuilder
    private func dotFill(for option: AppTheme, palette: ThemePalette) -> some View {
        if option == .system {
            ZStack {
                Circle().fill(Color.white)
                Circle()
                    .fill(Color.black)
                    .mask(
                        Rectangle()
                            .frame(width: Self.dotSize, height: Self.dotSize)
                            .offset(x: Self.dotSize / 2)
                    )
            }
        } else {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [palette.primary, palette.primaryDeep],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }
}

struct MenuBarView_Previews: PreviewProvider {
    static var previews: some View {
        MenuBarView()
    }
}
