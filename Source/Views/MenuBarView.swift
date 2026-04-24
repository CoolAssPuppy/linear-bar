import SwiftUI

/// The popover view shown from the menu bar button. Hosts the chrome —
/// title bar + tab bar + bottom bar — and swaps in the selected tab's
/// content. All five tabs are live views; Inbox is the default.
struct MenuBarView: View {
    @State private var selectedTab: Tab = .inbox
    @State private var isRefreshing = false
    @State private var lastRefreshedAt: Date = Date()
    @ObservedObject private var themeStore = ThemeStore.shared

    @ObservedObject private var appSettings = AppSettings.shared

    var body: some View {
        let theme = themeStore.palette
        return ZStack {
            VStack(spacing: 0) {
                if appSettings.accounts.isEmpty {
                    PopoverWelcomeView()
                } else {
                    HeaderBar(lastRefreshedAt: lastRefreshedAt,
                              onCreate: openLinearCreate,
                              isRefreshing: isRefreshing)
                    Divider().background(theme.divider)

                    tabBar
                    Divider().background(theme.divider)

                    contentArea
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(theme.background)
                }

                Divider().background(theme.divider)
                BottomBar(onRefresh: triggerRefresh,
                          onOpenWindow: openMainWindow,
                          onSettings: openSettings,
                          onQuit: quitApp)
            }

            ToastOverlay()
        }
        .frame(width: 440, height: 540)
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
        case .faves:
            FavesView()
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

    private func openMainWindow() {
        NotificationCenter.default.post(name: .mainWindowRequested, object: nil)
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
                url = SafeExternalURL.linearURL(orgSlug: orgSlug, pathComponents: ["team", teamKey, "new"])
            } else {
                url = SafeExternalURL.linearURL(orgSlug: orgSlug, pathComponents: ["issue", "new"])
            }
        case "project":
            url = SafeExternalURL.linearURL(orgSlug: orgSlug, pathComponents: ["projects", "new"])
        case "initiative":
            url = SafeExternalURL.linearURL(orgSlug: orgSlug, pathComponents: ["roadmap"])
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
        case inbox, faves, mine, recent, pulse, search

        var label: String {
            switch self {
            case .inbox:  return "Inbox"
            case .faves:  return "Faves"
            case .mine:   return "Mine"
            case .recent: return "Recent"
            case .pulse:  return "Pulse"
            case .search: return "Search"
            }
        }

        var icon: String {
            switch self {
            case .inbox:  return "tray"
            case .faves:  return "star"
            case .mine:   return "checkmark.circle"
            case .recent: return "clock"
            case .pulse:  return "waveform.path.ecg"
            case .search: return "magnifyingglass"
            }
        }

        init(defaultTab: DefaultTab) {
            switch defaultTab {
            case .inbox:  self = .inbox
            case .faves:  self = .faves
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
                        .lineLimit(1)
                        .fixedSize()
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

    @ObservedObject private var settings = AppSettings.shared
    @Environment(\.theme) private var theme

    var body: some View {
        // ZStack so the workspace sits dead-center regardless of what the
        // side elements' widths end up being. An HStack with spacers would
        // drift as soon as the workspace name grew longer than the brand +
        // new button could balance.
        ZStack {
            if settings.accounts.count > 1 {
                WorkspacePicker().fixedSize()
            } else {
                WorkspacePill().fixedSize()
            }

            HStack(spacing: 0) {
                BrandMark()
                Spacer(minLength: 0)
                newMenu
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(theme.surface)
    }

    private var newMenu: some View {
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
}

private struct BrandMark: View {
    var body: some View {
        CheckmarkBrandMark(size: 22, glyphSize: 14)
    }
}

/// Reusable brand tile: dark square with a soft amber glow and the
/// Strategic Nerds checkmark. Sized by the caller — popover header uses
/// 22pt, Welcome hero uses 64pt.
struct CheckmarkBrandMark: View {
    let size: CGFloat
    let glyphSize: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#1E1E1E"), Color(hex: "#0A0A0A")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color(hex: "#FDB817").opacity(0.28), radius: size * 0.3)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: "#FDB817").opacity(0.22), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.6
                    )
                )
                .frame(width: size * 1.15, height: size * 1.15)

            LinearGlyph()
                .stroke(
                    Color(hex: "#FDB817"),
                    style: StrokeStyle(lineWidth: max(size * 0.09, 1.2), lineCap: .round, lineJoin: .round)
                )
                .frame(width: glyphSize, height: glyphSize)
        }
        .frame(width: size, height: size)
    }
}

/// SwiftUI path for the Linear-style brand mark. Geometry is shared with the
/// menu bar icon renderer via `LinearGlyphStrokes` so both surfaces always
/// match pixel-for-pixel.
struct LinearGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        let scaleX = rect.width / LinearGlyphStrokes.boxSize
        let scaleY = rect.height / LinearGlyphStrokes.boxSize

        var path = Path()
        for (from, to) in LinearGlyphStrokes.endpoints {
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
    @State private var coordinator = WorkspaceMenuCoordinator()
    @State private var anchorFrame: CGRect = .zero

    var body: some View {
        // SwiftUI's `Menu` bridges to an NSPopUpButton-style control on macOS,
        // which sizes any image in its label using the image's natural pixel
        // dimensions and ignores SwiftUI `.frame` modifiers underneath. That
        // blew the workspace logo up to ~250pt. Driving an NSMenu manually
        // from a plain Button keeps the chip in pure SwiftUI layout.
        Button(action: presentMenu) {
            HStack(spacing: 6) {
                WorkspaceLogo(account: primaryAccount, size: 18)

                Text(workspaceLabel)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(theme.foreground)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(theme.tertiary)
            }
            .contentShape(Rectangle())
            .background(
                GeometryReader { geo in
                    Color.clear
                        .preference(key: WorkspaceAnchorKey.self,
                                    value: geo.frame(in: .global))
                }
            )
        }
        .buttonStyle(.plain)
        .help("Switch workspace")
        .onPreferenceChange(WorkspaceAnchorKey.self) { anchorFrame = $0 }
    }

    private func presentMenu() {
        coordinator.settings = settings
        let menu = NSMenu()
        let primary = primaryAccount
        for account in settings.accounts {
            let item = NSMenuItem(
                title: account.workspaceLabel,
                action: #selector(WorkspaceMenuCoordinator.selectAccount(_:)),
                keyEquivalent: ""
            )
            item.target = coordinator
            item.representedObject = account.email
            item.state = (account.email == primary?.email) ? .on : .off
            item.image = Self.workspaceIcon(for: account)
            menu.addItem(item)
        }

        // Position the menu in the popover's contentView coordinate space
        // (AppKit bottom-left origin) so the upper-left of the menu lands
        // at the lower-left of the chip. Fall back to the mouse location
        // only if we can't get a handle on the window.
        guard let contentView = NSApp.keyWindow?.contentView else {
            menu.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
            return
        }
        let location = NSPoint(
            x: anchorFrame.minX,
            y: contentView.bounds.height - anchorFrame.maxY
        )
        menu.popUp(positioning: nil, at: location, in: contentView)
    }

    private var primaryAccount: LinearAccount? {
        settings.accounts.first(where: { $0.isEnabled && $0.authStatus == .valid })
    }

    private var workspaceLabel: String {
        primaryAccount?.workspaceLabel ?? "No workspace"
    }

    /// Renders a small rounded-square initial tile for each workspace in
    /// the menu. Matches the in-app `WorkspaceLogo`'s fallback style so
    /// the menu reads as a continuation of the chip.
    private static func workspaceIcon(for account: LinearAccount, size: CGFloat = 18) -> NSImage {
        let pixelSize = NSSize(width: size, height: size)
        let tint = Self.nsColorFromHex(account.color ?? "#5E6AD2")
        let initial = account.workspaceLabel.first
            .map { String($0).uppercased() } ?? "?"

        let image = NSImage(size: pixelSize, flipped: false) { rect in
            let path = NSBezierPath(
                roundedRect: rect,
                xRadius: rect.width * 0.22,
                yRadius: rect.height * 0.22
            )
            tint.setFill()
            path.fill()

            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: rect.width * 0.55, weight: .bold),
                .foregroundColor: NSColor.white.withAlphaComponent(0.92)
            ]
            let attributed = NSAttributedString(string: initial, attributes: attributes)
            let textSize = attributed.size()
            attributed.draw(at: NSPoint(
                x: (rect.width - textSize.width) / 2,
                y: (rect.height - textSize.height) / 2
            ))
            return true
        }
        // Keep our tint intact — NSMenuItem otherwise treats single-tone
        // images as templates and washes them out in dark mode.
        image.isTemplate = false
        return image
    }

    private static func nsColorFromHex(_ hex: String) -> NSColor {
        let trimmed = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var raw: UInt64 = 0
        Scanner(string: trimmed).scanHexInt64(&raw)
        let r = CGFloat((raw >> 16) & 0xFF) / 255
        let g = CGFloat((raw >> 8) & 0xFF) / 255
        let b = CGFloat(raw & 0xFF) / 255
        return NSColor(srgbRed: r, green: g, blue: b, alpha: 1)
    }
}

/// Anchor-rect PreferenceKey used by WorkspacePicker to report the chip's
/// on-screen position up to the parent so the NSMenu opens directly below
/// the chip rather than at the mouse cursor.
private struct WorkspaceAnchorKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

/// Target object for the NSMenu — plain NSObject because NSMenuItem.target
/// won't accept a SwiftUI struct. Holds a weak ref to AppSettings and
/// reorders `accounts` on selection so `primaryValidAccount` resolves to
/// the chosen workspace.
@MainActor
private final class WorkspaceMenuCoordinator: NSObject {
    weak var settings: AppSettings?

    @objc func selectAccount(_ sender: NSMenuItem) {
        guard let email = sender.representedObject as? String,
              let settings,
              let index = settings.accounts.firstIndex(where: { $0.email == email }),
              index != 0 else {
            return
        }
        var reordered = settings.accounts
        let account = reordered.remove(at: index)
        reordered.insert(account, at: 0)
        settings.accounts = reordered
        NotificationCenter.default.post(name: .accountSelected, object: account)
        NotificationCenter.default.post(name: .refreshAllData, object: nil)
    }
}

/// Read-only counterpart to `WorkspacePicker` used when only a single
/// account is connected. Same logo + label, no chevron, no menu.
private struct WorkspacePill: View {
    @Environment(\.theme) private var theme
    @ObservedObject private var settings = AppSettings.shared

    var body: some View {
        HStack(spacing: 6) {
            WorkspaceLogo(account: account, size: 18)
            Text(account?.workspaceLabel ?? "Workspace")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(theme.foreground)
                .lineLimit(1)
                .truncationMode(.tail)
        }
    }

    private var account: LinearAccount? {
        settings.accounts.first(where: { $0.isEnabled && $0.authStatus == .valid })
    }
}

/// Renders the Linear workspace logo with a graceful fallback to the
/// workspace initial in the account's tint color. Used in the popover
/// header, sidebar, and account list so the same art appears everywhere.
///
/// Uses a manual URLSession load + `Image(nsImage:)` instead of
/// `AsyncImage`. Inside a SwiftUI `Menu` label, AsyncImage's resolved
/// image leaks its intrinsic content size past every `.frame` and
/// `.clipped` modifier and blows out the parent. Loading manually and
/// rendering with `.resizable()` keeps the layout deterministic.
struct WorkspaceLogo: View {
    let account: LinearAccount?
    let size: CGFloat

    @Environment(\.theme) private var theme
    @StateObject private var loader = WorkspaceLogoLoader()

    var body: some View {
        Group {
            if let nsImage = loader.image {
                Image(nsImage: nsImage)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipped()
            } else {
                initialTile
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
        .fixedSize()
        .onAppear { loader.load(urlString: account?.organizationLogoUrl) }
        .onChange(of: account?.organizationLogoUrl) { _, newValue in
            loader.load(urlString: newValue)
        }
    }

    private var initialTile: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                .fill(tintColor)
            Text(String(initial))
                .font(.system(size: size * 0.55, weight: .bold))
                .foregroundStyle(Color.white.opacity(0.92))
        }
    }

    private var initial: Character {
        let label = account?.workspaceLabel ?? "?"
        return label.first?.uppercased().first ?? "?"
    }

    private var tintColor: Color {
        if let hex = account?.color { return Color(hex: hex) }
        return theme.primary
    }
}

@MainActor
private final class WorkspaceLogoLoader: ObservableObject {
    @Published var image: NSImage?
    private var loadedURL: String?
    private var task: URLSessionDataTask?

    func load(urlString: String?) {
        guard let urlString,
              let url = SafeExternalURL.httpsURL(from: urlString) else {
            image = nil
            loadedURL = nil
            task?.cancel()
            return
        }
        if urlString == loadedURL { return }
        loadedURL = urlString

        task?.cancel()
        task = URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data, let nsImage = NSImage(data: data) else { return }
            DispatchQueue.main.async {
                self?.image = nsImage
            }
        }
        task?.resume()
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

            AppIconButton(systemName: "power", help: "Quit Menu Bar for Linear", action: onQuit)
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
