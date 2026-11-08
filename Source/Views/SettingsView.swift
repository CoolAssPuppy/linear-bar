//  SettingsView.swift
//  Linear Bar
//  Copyright (c) 2026 Strategic Nerds. All rights reserved.

import SwiftUI
import AppKit
import KeyboardShortcuts

// MARK: - Global keyboard shortcut name

extension KeyboardShortcuts.Name {
    static let toggleLinearBar = Self("toggleLinearBar")
}

/// Content of the Settings drawer.
///
struct SettingsView: View {
    @ObservedObject private var settings = AppSettings.shared
    @StateObject private var updater = UpdaterManager.shared
    @StateObject private var loginItem = LoginItemController()
    @AppStorage("showUnreadCount") private var showUnreadCount = true
    @State private var telemetryOptIn: Bool = Telemetry.isOptedIn

    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 14) {
            generalCard
            appearanceCard
            keyboardCard
            updatesCard
            contactCard
        }
        .frame(maxWidth: 620)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 22)
        .padding(.vertical, 18)
    }

    // MARK: - General

    private var generalCard: some View {
        AppCard("General") {
            VStack(spacing: 0) {
                AppSettingRow(
                    "Launch at login",
                    description: "Start Menu Bar for Linear when you log in."
                ) {
                    Toggle("", isOn: Binding(
                        get: { loginItem.isEnabled },
                        set: { loginItem.setEnabled($0) }
                    ))
                        .labelsHidden()
                        .accessibilityLabel("Launch at login")
                        .toggleStyle(.switch)
                        .controlSize(.small)
                        .tint(theme.primary)
                }

                AppRowDivider().padding(.vertical, 10)

                AppSettingRow(
                    "Show unread count in menu bar",
                    description: "Display total unread issues next to the icon."
                ) {
                    Toggle("", isOn: $showUnreadCount)
                        .labelsHidden()
                        .accessibilityLabel("Show unread count in menu bar")
                        .toggleStyle(.switch)
                        .controlSize(.small)
                        .tint(theme.primary)
                }

                AppRowDivider().padding(.vertical, 10)

                AppSettingRow(
                    "Default tab",
                    description: "Which tab to open first in the menu bar popover."
                ) {
                    Picker("", selection: Binding(
                        get: { settings.defaultTab },
                        set: { settings.defaultTab = $0 }
                    )) {
                        ForEach(DefaultTab.allCases) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.menu)
                    .appBoxedPicker()
                    .accessibilityLabel("Default tab")
                }

                AppRowDivider().padding(.vertical, 10)

                AppSettingRow(
                    "Sync settings to iCloud",
                    description: "Keep connected workspaces and preferences in step across your Macs. Tokens stay on each device."
                ) {
                    Toggle("", isOn: Binding(
                        get: { settings.iCloudSyncEnabled },
                        set: { settings.iCloudSyncEnabled = $0 }
                    ))
                    .labelsHidden()
                    .accessibilityLabel("Sync settings to iCloud")
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .tint(theme.primary)
                }

                AppRowDivider().padding(.vertical, 10)

                AppSettingRow(
                    "Send anonymous diagnostics",
                    description: "Share usage events and crash reports. Issue text, URLs, names, and email addresses are excluded."
                ) {
                    Toggle("", isOn: Binding(
                        get: { telemetryOptIn },
                        set: { newValue in
                            telemetryOptIn = newValue
                            Telemetry.setOptedIn(newValue)
                        }
                    ))
                    .labelsHidden()
                    .accessibilityLabel("Send anonymous diagnostics")
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .tint(theme.primary)
                }
            }
        }
        .alert(
            "Launch at Login",
            isPresented: Binding(
                get: { loginItem.errorMessage != nil },
                set: { if !$0 { loginItem.clearError() } }
            )
        ) {
            Button("OK", role: .cancel) { loginItem.clearError() }
        } message: {
            Text(loginItem.errorMessage ?? "")
        }
    }

    private var appearanceCard: some View {
        AppCard("Appearance") {
            AppSettingRow("Theme") {
                ThemeSelector()
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous))
    }

    // MARK: - Keyboard

    private var keyboardCard: some View {
        AppCard("Keyboard Shortcuts") {
            AppSettingRow(
                "Toggle Menu Bar for Linear",
                description: "Global shortcut to open the menu bar popover from any app."
            ) {
                KeyboardShortcuts.Recorder(for: .toggleLinearBar)
            }
        }
    }

    // MARK: - Demo mode

    private var demoModeCard: some View {
        AppCard("Demo Mode") {
            AppSettingRow(
                "Show sample data",
                description: "Replaces your live data with fictional content. Handy for screenshots or demos — no network calls are made while on."
            ) {
                Toggle("", isOn: Binding(
                    get: { settings.demoModeEnabled },
                    set: { settings.demoModeEnabled = $0 }
                ))
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.small)
                .tint(theme.primary)
            }
        }
    }

    // MARK: - Updates

    private var updatesCard: some View {
        AppCard("Updates") {
            VStack(spacing: 0) {
                AppSettingRow("Automatically check for updates", description: nil) {
                    Toggle("", isOn: $updater.automaticallyChecksForUpdates)
                        .labelsHidden()
                        .accessibilityLabel("Automatically check for updates")
                        .toggleStyle(.switch)
                        .controlSize(.small)
                        .tint(theme.primary)
                }

                AppRowDivider().padding(.vertical, 10)

                AppSettingRow("Current version", description: nil) {
                    Text(appVersion)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(theme.foreground)
                }

                AppRowDivider().padding(.vertical, 10)

                Button { UpdaterManager.shared.checkForUpdates() } label: {
                    Text("Check for updates…")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(theme.foreground)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                                .strokeBorder(theme.borderStrong, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Contact

    private var contactCard: some View {
        AppCard("Contact") {
            VStack(alignment: .leading, spacing: 10) {
                contactRow(
                    iconView: AnyView(
                        Image(systemName: "ladybug.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(theme.muted)
                    ),
                    title: "bugs@strategicnerds.com",
                    url: SafeExternalURL.mustParse("mailto:bugs@strategicnerds.com")
                )
                contactRow(
                    iconView: AnyView(
                        Image("GitHubMark")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 13, height: 13)
                            .foregroundStyle(theme.muted)
                    ),
                    title: "coolasspuppy/linear-bar",
                    url: SafeExternalURL.mustParse("https://github.com/CoolAssPuppy/linear-bar")
                )
                contactRow(
                    iconView: AnyView(
                        Image(systemName: "cup.and.saucer.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(theme.muted)
                    ),
                    title: "Buy me coffee",
                    url: SafeExternalURL.mustParse("https://venmo.com/u/coolasspuppy")
                )
                contactRow(
                    iconView: AnyView(
                        Image(systemName: "book.closed.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(theme.muted)
                    ),
                    title: "Buy my book",
                    url: SafeExternalURL.mustParse("https://www.strategicnerds.com/picksandshovels")
                )
            }
        }
    }

    private func contactRow(iconView: AnyView, title: String, url: URL) -> some View {
        Link(destination: url) {
            HStack(spacing: 8) {
                iconView
                    .frame(width: 16, alignment: .center)
                Text(title)
                    .font(.system(size: 12))
                    .foregroundStyle(theme.primary)
            }
        }
        .buttonStyle(.plain)
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
}

private struct ThemeSelector: View {
    @ObservedObject private var store = ThemeStore.shared
    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isExpanded = false
    @FocusState private var focusedTheme: AppTheme?
    @Namespace private var circleNamespace

    private var selectionAnimation: Animation? {
        reduceMotion ? nil : .spring(response: 0.32, dampingFraction: 0.72)
    }

    var body: some View {
        HStack(spacing: 6) {
            Text(store.current.label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(theme.foreground)
                .lineLimit(1)
                .frame(width: 75, alignment: .trailing)

            HStack(spacing: 3) {
                if isExpanded {
                    ForEach(AppTheme.allCases.filter { $0 != store.current }) { option in
                        Button {
                            withAnimation(selectionAnimation) {
                                store.current = option
                                isExpanded = false
                            }
                        } label: {
                            themeCircle(for: option)
                                .matchedGeometryEffect(id: option.id, in: circleNamespace)
                        }
                        .buttonStyle(.plain)
                        .frame(width: 20, height: 24)
                        .focusable()
                        .focused($focusedTheme, equals: option)
                        .accessibilityLabel("Use \(option.label) theme")
                        .help(option.label)
                    }
                }

                Button {
                    withAnimation(selectionAnimation) { isExpanded.toggle() }
                } label: {
                    themeCircle(for: store.current)
                        .matchedGeometryEffect(id: store.current.id, in: circleNamespace)
                }
                .buttonStyle(.plain)
                .frame(width: 24, height: 24)
                .focusable()
                .focused($focusedTheme, equals: store.current)
                .accessibilityLabel(isExpanded ? "Hide theme choices" : "Show theme choices")
                .accessibilityValue(store.current.label)
                .accessibilityHint("Current theme")
                .help(isExpanded ? "Hide themes" : "Choose theme")
            }
        }
        .frame(width: 320, alignment: .trailing)
        .clipped()
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(selectionAnimation) { isExpanded = hovering }
        }
    }

    @ViewBuilder
    private func themeCircle(for option: AppTheme) -> some View {
        Group {
            if option == .system {
                Circle()
                    .fill(.white)
                    .overlay(alignment: .trailing) {
                        Rectangle().fill(.black).frame(width: 6)
                    }
                    .clipShape(Circle())
            } else {
                Circle().fill(option.palette.primary)
            }
        }
        .frame(width: 12, height: 12)
        .overlay(Circle().strokeBorder(theme.foreground.opacity(0.7), lineWidth: 1))
        .overlay {
            if focusedTheme == option {
                Circle()
                    .strokeBorder(theme.foreground, lineWidth: 1.5)
                    .frame(width: 20, height: 20)
            }
        }
    }
}

#Preview {
    SettingsView()
        .frame(width: 980, height: 560)
}
