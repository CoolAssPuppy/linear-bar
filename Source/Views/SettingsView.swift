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
                    supportCard
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
        AppCard("Updates", trailing: {
            HStack(spacing: 5) {
                Circle().fill(theme.success).frame(width: 5, height: 5)
                Text("UP TO DATE")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(0.3)
                    .foregroundStyle(theme.success)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(
                Capsule().fill(theme.success.opacity(0.10))
            )
            .overlay(
                Capsule().strokeBorder(theme.success.opacity(0.3), lineWidth: 1)
            )
        }) {
            VStack(spacing: 0) {
                AppSettingRow(
                    "Check for updates automatically",
                    description: "Checks once a day, prompts before installing."
                ) {
                    Toggle("", isOn: $updater.automaticallyChecksForUpdates)
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .controlSize(.small)
                        .tint(theme.primary)
                }

                AppRowDivider().padding(.vertical, 10)

                AppSettingRow(
                    "Current version \(appVersion)",
                    description: nil
                ) {
                    AppSecondaryButton(title: "Check now", systemImage: "arrow.down.circle") {
                        UpdaterManager.shared.checkForUpdates()
                    }
                }
            }
        }
    }

    // MARK: - Support

    private var supportCard: some View {
        AppCard("Support") {
            VStack(alignment: .leading, spacing: 12) {
                Text("Menu Bar for Linear is built by one person on nights and weekends. If it saves you time, consider buying me a coffee or starring the repo.")
                    .font(.system(size: 11))
                    .foregroundStyle(theme.foregroundSoft)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    Link(destination: URL(string: "https://venmo.com/coolasspuppy")!) {
                        HStack(spacing: 7) {
                            Image(systemName: "cup.and.saucer.fill")
                                .font(.system(size: 11))
                            Text("Buy me a coffee")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(
                            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [theme.primary, theme.primaryDeep],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                    }
                    .buttonStyle(.plain)

                    Link(destination: URL(string: "https://github.com/CoolAssPuppy/linear-bar")!) {
                        HStack(spacing: 6) {
                            Image(systemName: "star")
                                .font(.system(size: 11))
                            Text("Star on GitHub")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundStyle(theme.foreground)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 7)
                        .background(
                            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                                .fill(theme.cardInset)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                                .strokeBorder(theme.borderStrong, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
}

#Preview {
    SettingsView()
        .frame(width: 980, height: 560)
}
