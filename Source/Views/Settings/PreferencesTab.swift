import SwiftUI

/// Tab view for app preferences and settings
struct PreferencesTab: View {
    @AppStorage("defaultViewMode") private var defaultViewModeRaw = ViewMode.createdByMe.rawValue
    @AppStorage("defaultTab") private var defaultTabRaw = DefaultTab.favorites.rawValue
    @AppStorage("refreshInterval") private var refreshIntervalRaw = RefreshInterval.fifteenMinutes.rawValue
    @AppStorage("showCompletedItems") private var showCompletedItems = true
    @AppStorage("showCanceledItems") private var showCanceledItems = false
    @AppStorage("launchAtLogin") private var launchAtLogin = false

    @Environment(\.theme) private var theme

    private var defaultViewMode: Binding<ViewMode> {
        Binding(
            get: { ViewMode(rawValue: defaultViewModeRaw) ?? .createdByMe },
            set: { defaultViewModeRaw = $0.rawValue }
        )
    }

    private var defaultTab: Binding<DefaultTab> {
        Binding(
            get: { DefaultTab(rawValue: defaultTabRaw) ?? .favorites },
            set: { defaultTabRaw = $0.rawValue }
        )
    }

    private var refreshInterval: Binding<RefreshInterval> {
        Binding(
            get: { RefreshInterval(rawValue: refreshIntervalRaw) ?? .fifteenMinutes },
            set: { refreshIntervalRaw = $0.rawValue }
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Form {
                    Section {
                        defaultTabPicker
                        recentViewModePicker
                    } header: {
                        sectionHeader(icon: "star.circle.fill", title: "Default View")
                    }

                    Section {
                        showCompletedToggle
                        showCanceledToggle
                    } header: {
                        sectionHeader(icon: "line.3.horizontal.decrease.circle.fill", title: "Filters")
                    }

                    Section {
                        refreshIntervalPicker
                    } header: {
                        sectionHeader(icon: "arrow.clockwise.circle.fill", title: "Refresh")
                    }

                    Section {
                        launchAtLoginToggle
                    } header: {
                        sectionHeader(icon: "power.circle.fill", title: "Startup")
                    }

                    Section {
                        buyMeCoffeeButton
                    } header: {
                        sectionHeader(icon: "cup.and.saucer.fill", title: "Support")
                    }

                    Section {
                        aboutInfo
                    } header: {
                        sectionHeader(icon: "info.circle.fill", title: "About")
                    }
                }
                .formStyle(.grouped)
            }
            .padding(20)
        }
        .background(theme.background)
        .onChange(of: defaultViewModeRaw) { newValue in
            syncToiCloud(newValue, forKey: "defaultViewMode")
        }
        .onChange(of: defaultTabRaw) { newValue in
            syncToiCloud(newValue, forKey: "defaultTab")
        }
        .onChange(of: refreshIntervalRaw) { newValue in
            syncToiCloud(newValue, forKey: "refreshInterval")
        }
        .onChange(of: showCompletedItems) { newValue in
            syncToiCloud(newValue, forKey: "showCompletedItems")
        }
        .onChange(of: showCanceledItems) { newValue in
            syncToiCloud(newValue, forKey: "showCanceledItems")
        }
        .onChange(of: launchAtLogin) { newValue in
            syncToiCloud(newValue, forKey: "launchAtLogin")
        }
    }

    private func syncToiCloud<T>(_ value: T, forKey key: String) {
        let iCloudStore = NSUbiquitousKeyValueStore.default
        iCloudStore.set(value, forKey: key)
        iCloudStore.synchronize()
    }

    // MARK: - Section Header

    private func sectionHeader(icon: String, title: String) -> some View {
        HStack(spacing: AppStyle.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(theme.muted)
            Text(title)
                .font(AppStyle.Font.sectionHeader)
                .foregroundStyle(theme.foreground)
        }
    }

    // MARK: - Default View Section

    private var defaultTabPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Open to tab:")
                .font(.body)

            Picker("", selection: defaultTab) {
                ForEach(DefaultTab.allCases) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)

            Text("Choose which tab to open when launching IssueBar")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var recentViewModePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent tab default:")
                .font(.body)

            Picker("", selection: defaultViewMode) {
                ForEach(ViewMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            Text("Choose which view to show in the Recent tab")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Filters Section

    private var showCompletedToggle: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle("Show completed items", isOn: $showCompletedItems)

            Text("Display items that have been marked as done")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var showCanceledToggle: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle("Show canceled items", isOn: $showCanceledItems)

            Text("Display items that have been canceled")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Refresh Section

    private var refreshIntervalPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Refresh interval:")
                .font(.body)

            Picker("", selection: refreshInterval) {
                ForEach(RefreshInterval.allCases) { interval in
                    Text(interval.rawValue).tag(interval)
                }
            }
            .pickerStyle(.menu)

            Text("How often to automatically refresh your Linear data")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Startup Section

    private var launchAtLoginToggle: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle("Launch at login", isOn: $launchAtLogin)

            Text("Automatically start IssueBar when you log in")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Support Section

    private var buyMeCoffeeButton: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Linear Bar is built by one person on nights and weekends. If it saves you time, consider buying me a coffee or starring the repo.")
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

    // MARK: - About Section

    private var aboutInfo: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Made with love by Strategic Nerds, Inc.")
                .font(.caption)
                .foregroundColor(.secondary)

            Text("\u{00A9} \(String(Calendar.current.component(.year, from: Date()))) Strategic Nerds, Inc.")
                .font(.caption)
                .foregroundColor(.secondary)

            if let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                Text("Build \(buildNumber)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Link("Contribute on GitHub", destination: URL(string: "https://github.com/coolasspuppy/linear-bar")!)
                .font(.caption)
        }
    }
}
