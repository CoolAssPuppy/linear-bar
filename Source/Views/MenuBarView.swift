import SwiftUI

/// The popover view shown from the menu bar button. Hosts the chrome —
/// title bar + tab bar + bottom bar — and swaps in the selected tab's
/// content. All five tabs are live views; Inbox is the default.
struct MenuBarView: View {
    @State private var selectedTab: Tab = .inbox
    @State private var isRefreshing = false
    @State private var lastRefreshedAt: Date = Date()
    @ObservedObject private var themeStore = ThemeStore.shared

    var body: some View {
        let theme = themeStore.palette
        return VStack(spacing: 0) {
            HeaderBar(lastRefreshedAt: lastRefreshedAt,
                      onCreate: openLinearCreate,
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
        .frame(width: 400, height: 540)
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
        selectedTab = Tab(defaultTab: AppSettings.shared.defaultTab)
    }

    // MARK: - Tab bar

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { tab in
                TabButton(tab: tab, selectedTab: $selectedTab)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, AppSpacing.sm)
    }

    // MARK: - Content

    @ViewBuilder
    private var contentArea: some View {
        switch selectedTab {
        case .inbox:
            InboxView()
        case .mine:
            MyIssuesView()
        case .recent:
            RecentView()
        case .pulse:
            PulseView()
        case .search:
            SearchView()
        }
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
        let url: URL?

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

    // MARK: - Tab enum

    enum Tab: String, CaseIterable {
        case inbox, mine, recent, pulse, search

        var label: String {
            switch self {
            case .inbox:  return "Inbox"
            case .mine:   return "Mine"
            case .recent: return "Recent"
            case .pulse:  return "Pulse"
            case .search: return "Search"
            }
        }

        var icon: String {
            switch self {
            case .inbox:  return "tray"
            case .mine:   return "checkmark.circle"
            case .recent: return "clock"
            case .pulse:  return "waveform.path.ecg"
            case .search: return "magnifyingglass"
            }
        }

        init(defaultTab: DefaultTab) {
            switch defaultTab {
            case .inbox:  self = .inbox
            case .mine:   self = .mine
            case .recent: self = .recent
            case .pulse:  self = .pulse
            case .search: self = .search
            }
        }
    }
}

// MARK: - Tab button

private struct TabButton: View {
    let tab: MenuBarView.Tab
    @Binding var selectedTab: MenuBarView.Tab
    @Environment(\.theme) private var theme
    @State private var isHovered = false

    var body: some View {
        Button(action: { selectedTab = tab }) {
            VStack(spacing: 5) {
                HStack(spacing: 5) {
                    Image(systemName: tab.icon)
                        .font(.system(size: 11, weight: .medium))
                    Text(tab.label)
                        .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                }
                .foregroundStyle(foregroundColor)
                .padding(.horizontal, 6)
                .padding(.top, 6)
                .padding(.bottom, 4)

                Rectangle()
                    .fill(isSelected ? theme.primary : Color.clear)
                    .frame(height: 1.5)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }

    private var isSelected: Bool { selectedTab == tab }

    private var foregroundColor: Color {
        if isSelected { return theme.foreground }
        if isHovered { return theme.foregroundSoft }
        return theme.muted
    }
}

// MARK: - Header bar

private struct HeaderBar: View {
    let lastRefreshedAt: Date
    let onCreate: (String) -> Void
    let isRefreshing: Bool

    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: 10) {
            BrandMark()
            WorkspacePicker()

            Menu {
                Button { onCreate("issue") } label: {
                    Label("New Issue", systemImage: "checkmark.circle")
                }
                Button { onCreate("project") } label: {
                    Label("New Project", systemImage: "square.grid.2x2")
                }
                Button { onCreate("initiative") } label: {
                    Label("New Initiative", systemImage: "diamond")
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(theme.foreground)
                    Text("New")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(theme.foreground)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(theme.tertiary)
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                        .fill(theme.card)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                        .strokeBorder(theme.border, lineWidth: 1)
                )
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
            .help("Create new Linear item")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(theme.surface)
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
                .shadow(color: theme.primary.opacity(0.28), radius: 4)

            LinearGlyph()
                .stroke(theme.primaryForeground, style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
                .frame(width: 12, height: 12)
        }
        .frame(width: 22, height: 22)
    }
}

/// SwiftUI path for the Linear-style mark: five parallel diagonals on a
/// 12×12 grid. Used in the header brand mark and mirrored in the menu bar
/// icon renderer so both surfaces visually match.
struct LinearGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        // Strokes expressed in the design's 12×12 coordinate space; rescale
        // proportionally to whatever frame the caller supplies.
        let scaleX = rect.width / 12
        let scaleY = rect.height / 12
        let strokes: [(CGPoint, CGPoint)] = [
            (CGPoint(x: 1.2, y: 6.4),  CGPoint(x: 5.6, y: 10.8)),
            (CGPoint(x: 1.2, y: 3.4),  CGPoint(x: 8.6, y: 10.8)),
            (CGPoint(x: 2.2, y: 1.2),  CGPoint(x: 10.8, y: 9.8)),
            (CGPoint(x: 5.2, y: 1.2),  CGPoint(x: 10.8, y: 6.8)),
            (CGPoint(x: 8.2, y: 1.2),  CGPoint(x: 10.8, y: 3.8))
        ]

        var path = Path()
        for (from, to) in strokes {
            path.move(to: CGPoint(x: from.x * scaleX, y: from.y * scaleY))
            path.addLine(to: CGPoint(x: to.x * scaleX, y: to.y * scaleY))
        }
        return path
    }
}

// MARK: - Workspace picker

private struct WorkspacePicker: View {
    @Environment(\.theme) private var theme
    @ObservedObject private var settings = AppSettings.shared

    var body: some View {
        Menu {
            ForEach(settings.accounts) { account in
                Button {
                    // Selecting an account from the popover is a placeholder
                    // while multi-account picking lands. For now the chip
                    // reflects whichever account is already "primary".
                } label: {
                    HStack {
                        Text(account.name ?? account.email)
                        if account.email == settings.accounts.first?.email {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Text(workspaceLabel)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(theme.foreground)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer(minLength: 0)

                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(theme.tertiary)
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                    .fill(theme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                    .strokeBorder(theme.border, lineWidth: 1)
            )
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .help("Switch workspace")
    }

    private var workspaceLabel: String {
        if let first = settings.accounts.first(where: { $0.isEnabled && $0.authStatus == .valid }) {
            return first.name ?? first.email
        }
        return "No workspace"
    }
}

// MARK: - Bottom bar

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

// MARK: - Theme strip

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
