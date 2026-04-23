//
//  MainView.swift
//  Linear Bar
//
//  Copyright (c) 2026 Strategic Nerds. All rights reserved.
//

import SwiftUI
import AppKit

/// The main window shell: sidebar + content + drawer overlay.
/// Mirrors `MainView` in mail-notifier.
struct LinearMainView: View {
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var themeStore = ThemeStore.shared
    @Binding var selection: String?
    @State private var isSettingsOpen = false

    var body: some View {
        let theme = themeStore.palette
        return ZStack(alignment: .top) {
            HStack(spacing: 0) {
                LinearSidebar(
                    selection: $selection,
                    onOpenSettings: { isSettingsOpen.toggle() }
                )
                .frame(width: 260)

                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(theme.background)

            SettingsDrawer(isPresented: $isSettingsOpen)
        }
        .frame(minWidth: 920, minHeight: 640)
        .background(WindowChrome(palette: theme))
        .environment(\.theme, theme)
        .environment(\.colorScheme, theme.isDark ? .dark : .light)
        .onReceive(NotificationCenter.default.publisher(for: .accountsDidUpdate)) { _ in
            if let email = selection,
               !settings.accounts.contains(where: { $0.email == email }) {
                selection = settings.accounts.first?.email
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .accountSelected)) { notification in
            if let account = notification.object as? LinearAccount {
                selection = account.email
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openSettingsDrawer)) { _ in
            isSettingsOpen = true
        }
    }

    @ViewBuilder
    private var content: some View {
        if settings.accounts.isEmpty || selection == "welcome" {
            LinearWelcomeView()
        } else if let email = selection,
                  let account = settings.accounts.first(where: { $0.email == email }) {
            LinearAccountView(account: account)
                .id(account.email)
        } else if let firstAccount = settings.accounts.first {
            LinearAccountView(account: firstAccount)
                .id(firstAccount.email)
                .onAppear {
                    selection = firstAccount.email
                }
        } else {
            LinearWelcomeView()
        }
    }
}

// MARK: - Window chrome configuration

private struct WindowChrome: NSViewRepresentable {
    let palette: ThemePalette

    func makeNSView(context: Context) -> ChromeView {
        ChromeView(palette: palette)
    }

    func updateNSView(_ nsView: ChromeView, context: Context) {
        nsView.palette = palette
        nsView.applyChrome()
    }
}

private final class ChromeView: NSView {
    var palette: ThemePalette

    init(palette: ThemePalette) {
        self.palette = palette
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        applyChrome()
    }

    func applyChrome() {
        guard let window else { return }
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.styleMask.insert(.fullSizeContentView)
        window.toolbar = nil
        window.appearance = palette.nsAppearance
        window.backgroundColor = palette.nsBackground
        window.isMovableByWindowBackground = true
    }
}

#Preview {
    LinearMainView(selection: .constant(nil))
        .frame(width: 1080, height: 720)
}
