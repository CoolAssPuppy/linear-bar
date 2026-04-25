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

/// Content of the Settings drawer (two-column card grid).
///
struct SettingsView: View {
    @ObservedObject private var settings = AppSettings.shared
    @StateObject private var updater = UpdaterManager.shared
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("showUnreadCount") private var showUnreadCount = true
    @State private var telemetryOptIn: Bool = Telemetry.isOptedIn

    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 14) {
                VStack(spacing: 14) {
                    generalCard
                    keyboardCard
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 14) {
                    updatesCard
                    contactCard
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 22)
            .padding(.top, 18)
            .padding(.bottom, 14)
        }
    }

    // MARK: - General

    private var generalCard: some View {
        AppCard("General") {
            VStack(spacing: 0) {
                AppSettingRow(
                    "Launch at login",
                    description: "Start Menu Bar for Linear when you log in."
                ) {
                    Toggle("", isOn: $launchAtLogin)
                        .labelsHidden()
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
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .tint(theme.primary)
                }

                AppRowDivider().padding(.vertical, 10)

                AppSettingRow(
                    "Send anonymous usage data",
                    description: "Help improve Menu Bar for Linear."
                ) {
                    Toggle("", isOn: Binding(
                        get: { telemetryOptIn },
                        set: { newValue in
                            telemetryOptIn = newValue
                            Telemetry.setOptedIn(newValue)
                        }
                    ))
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .tint(theme.primary)
                }
            }
        }
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
                    url: "mailto:bugs@strategicnerds.com"
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
                    url: "https://github.com/CoolAssPuppy/linear-bar"
                )
                contactRow(
                    iconView: AnyView(
                        Image(systemName: "cup.and.saucer.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(theme.muted)
                    ),
                    title: "Buy me coffee",
                    url: "https://venmo.com/u/coolasspuppy"
                )
                contactRow(
                    iconView: AnyView(
                        Image(systemName: "book.closed.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(theme.muted)
                    ),
                    title: "Buy my book",
                    url: "https://www.strategicnerds.com/picksandshovels"
                )
            }
        }
    }

    private func contactRow(iconView: AnyView, title: String, url: String) -> some View {
        Link(destination: URL(string: url)!) {
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

#Preview {
    SettingsView()
        .frame(width: 980, height: 560)
}
