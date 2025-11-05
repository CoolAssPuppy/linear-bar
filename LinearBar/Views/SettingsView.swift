import SwiftUI

/// Settings view for managing accounts and preferences
struct SettingsView: View {
    @ObservedObject private var settings = AppSettings.shared
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            headerBar

            Divider()

            TabView(selection: $selectedTab) {
                AccountsTab()
                    .tabItem {
                        Label("Accounts", systemImage: "person.crop.circle")
                    }
                    .tag(0)

                PreferencesTab()
                    .tabItem {
                        Label("Preferences", systemImage: "gearshape")
                    }
                    .tag(1)

                AboutTab()
                    .tabItem {
                        Label("About", systemImage: "info.circle")
                    }
                    .tag(2)
            }
        }
        .background(.ultraThinMaterial)
        .frame(width: 500, height: 600)
    }

    private var headerBar: some View {
        HStack {
            Text("LinearBar Settings")
                .font(.title2)
                .fontWeight(.semibold)

            Spacer()
        }
        .padding()
        .background(.regularMaterial)
    }
}

// MARK: - Accounts Tab

struct AccountsTab: View {
    @ObservedObject private var settings = AppSettings.shared
    @State private var accountToRemove: LinearAccount?
    @State private var showingRemoveAlert = false
    @State private var showingColorPicker = false
    @State private var selectedAccount: LinearAccount?

    var body: some View {
        VStack(spacing: 16) {
            if settings.accounts.isEmpty {
                emptyStateView
            } else {
                accountListView
            }

            Spacer()

            addAccountButton
        }
        .padding(20)
        .alert("Remove Account", isPresented: $showingRemoveAlert, presenting: accountToRemove) { account in
            Button("Remove", role: .destructive) {
                settings.removeAccount(account)
            }
            Button("Cancel", role: .cancel) {}
        } message: { account in
            Text("Are you sure you want to remove \(account.email)? This will stop syncing your Linear data.")
        }
        .sheet(isPresented: $showingColorPicker) {
            if let account = selectedAccount {
                ColorPickerView(account: account)
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No accounts connected")
                .font(.headline)

            Text("Add a Linear account to get started")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var accountListView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Connected Accounts")
                .font(.headline)

            ScrollView {
                VStack(spacing: 8) {
                    ForEach(settings.accounts) { account in
                        accountRow(account)
                    }
                }
            }
        }
    }

    private func accountRow(_ account: LinearAccount) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Account color indicator
                if let colorHex = account.color {
                    Circle()
                        .fill(Color(hex: colorHex))
                        .frame(width: 16, height: 16)
                } else {
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 16, height: 16)
                }

                VStack(alignment: .leading, spacing: 4) {
                    if let name = account.name {
                        Text(name)
                            .font(.system(size: 13, weight: .medium))
                    }
                    Text(account.email)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: {
                    selectedAccount = account
                    showingColorPicker = true
                }) {
                    Image(systemName: "paintpalette")
                }
                .buttonStyle(.borderless)
                .help("Change account color")

                Button("Remove") {
                    removeAccount(account)
                }
                .buttonStyle(.borderless)
                .foregroundColor(.red)
            }

            // Auth status warning
            if account.authStatus != .valid {
                Divider()
                    .padding(.vertical, 8)

                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 14))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(account.authStatus == .needsAuth ? "Sign in required" : "Authentication expired")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.orange)

                        Text("Click Sign In to restore access")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()

                    Button("Sign In") {
                        reconnectAccount(account)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .controlSize(.small)
                }
            }
        }
        .padding(12)
        .background(account.authStatus != .valid ? Color.orange.opacity(0.1) : Color(nsColor: .controlBackgroundColor).opacity(0.5))
        .cornerRadius(6)
    }

    private var addAccountButton: some View {
        Button(action: addLinearAccount) {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 16))
                Text("Add Linear Account")
                    .font(.system(size: 13))
            }
        }
        .buttonStyle(.bordered)
    }

    private func addLinearAccount() {
        LinearAuthService.shared.addLinearAccount { result in
            Task { @MainActor in
                switch result {
                case .success:
                    break
                case .failure(let error):
                    showError(error.localizedDescription)
                }
            }
        }
    }

    private func removeAccount(_ account: LinearAccount) {
        accountToRemove = account
        showingRemoveAlert = true
    }

    private func reconnectAccount(_ account: LinearAccount) {
        LinearAuthService.shared.addLinearAccount { result in
            Task { @MainActor in
                switch result {
                case .success:
                    break
                case .failure(let error):
                    showError(error.localizedDescription)
                }
            }
        }
    }

    private func showError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "Error"
        alert.informativeText = message
        alert.alertStyle = .critical
        alert.runModal()
    }
}

// MARK: - Preferences Tab

struct PreferencesTab: View {
    @ObservedObject private var settings = AppSettings.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Form {
                    // DEFAULT VIEW
                    Section {
                        defaultTabPicker
                        recentViewModePicker
                    } header: {
                        sectionHeader(icon: "star.circle.fill", title: "Default View", gradient: [.purple, .pink])
                    }

                    // FILTERS
                    Section {
                        showCompletedToggle
                        showCanceledToggle
                    } header: {
                        sectionHeader(icon: "line.3.horizontal.decrease.circle.fill", title: "Filters", gradient: [.blue, .cyan])
                    }

                    // REFRESH
                    Section {
                        refreshIntervalPicker
                    } header: {
                        sectionHeader(icon: "arrow.clockwise.circle.fill", title: "Refresh", gradient: [.green, .mint])
                    }

                    // STARTUP
                    Section {
                        launchAtLoginToggle
                    } header: {
                        sectionHeader(icon: "power.circle.fill", title: "Startup", gradient: [.orange, .yellow])
                    }
                }
                .formStyle(.grouped)
            }
            .padding(20)
        }
        .background(
            LinearGradient(
                colors: [
                    Color.accentColor.opacity(0.02),
                    Color.clear,
                    Color.purple.opacity(0.01)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    // MARK: - Section Header

    private func sectionHeader(icon: String, title: String, gradient: [Color]) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: gradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.primary)
        }
    }

    // MARK: - Default View Section

    private var defaultTabPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Open to tab:")
                .font(.body)

            Picker("", selection: $settings.defaultTab) {
                ForEach(DefaultTab.allCases) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)

            Text("Choose which tab to open when launching LinearBar")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var recentViewModePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent tab default:")
                .font(.body)

            Picker("", selection: $settings.defaultViewMode) {
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
            Toggle("Show completed items", isOn: $settings.showCompletedItems)

            Text("Display items that have been marked as done")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var showCanceledToggle: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle("Show canceled items", isOn: $settings.showCanceledItems)

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

            Picker("", selection: $settings.refreshInterval) {
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
            Toggle("Launch at login", isOn: $settings.launchAtLogin)

            Text("Automatically start LinearBar when you log in")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - About Tab

struct AboutTab: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.square.fill")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)

            Text("LinearBar")
                .font(.title)
                .fontWeight(.bold)

            Text("Quick access to Linear from your menu bar")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 8) {
                Text("Version 1.0.0")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("Build 1")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Link("View on GitHub", destination: URL(string: "https://github.com")!)
                .font(.caption)
        }
        .padding(40)
    }
}

// MARK: - Color Picker View

struct ColorPickerView: View {
    let account: LinearAccount
    @Environment(\.dismiss) private var dismiss
    @State private var selectedColor: Color

    private let availableColors: [String] = [
        "#5E6AD2", // Linear purple
        "#10B981", // green
        "#F59E0B", // orange
        "#EF4444", // red
        "#3B82F6", // blue
        "#8B5CF6", // purple
        "#EC4899", // pink
        "#14B8A6"  // teal
    ]

    init(account: LinearAccount) {
        self.account = account
        _selectedColor = State(initialValue: Color(hex: account.color ?? "#5E6AD2"))
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Choose Account Color")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 12) {
                ForEach(availableColors, id: \.self) { colorHex in
                    Circle()
                        .fill(Color(hex: colorHex))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Circle()
                                .stroke(account.color == colorHex ? Color.primary : Color.clear, lineWidth: 3)
                        )
                        .onTapGesture {
                            AppSettings.shared.setAccountColor(colorHex, forAccount: account.email)
                            dismiss()
                        }
                }
            }

            Button("Cancel") {
                dismiss()
            }
        }
        .padding(30)
        .frame(width: 300, height: 300)
    }
}
