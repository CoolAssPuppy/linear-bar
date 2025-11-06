import SwiftUI
import ObjectiveC

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
                        Label("Setup", systemImage: "gearshape")
                    }
                    .tag(1)
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
        .onChange(of: showingColorPicker) { isShowing in
            if isShowing, let account = selectedAccount {
                presentColorPicker(for: account)
            }
        }
    }

    private func presentColorPicker(for account: LinearAccount) {
        let colorPickerView = ColorPickerView(account: account, isPresented: $showingColorPicker)
        let hostingController = NSHostingController(rootView: colorPickerView)

        let window = NSWindow(contentViewController: hostingController)
        window.styleMask = [.titled, .closable]
        window.title = "Choose Color"
        window.setContentSize(NSSize(width: 340, height: 360))
        window.center()
        window.makeKeyAndOrderFront(nil)
        window.level = .floating

        // Store reference to prevent deallocation
        objc_setAssociatedObject(self, "colorPickerWindow", window, .OBJC_ASSOCIATION_RETAIN)
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
                // Account color indicator - clickable to change color
                Button(action: {
                    selectedAccount = account
                    showingColorPicker = true
                }) {
                    Circle()
                        .fill(Color(hex: account.color ?? "#5E6AD2"))
                        .frame(width: 20, height: 20)
                        .overlay(
                            Circle()
                                .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .help("Change account color")

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
    @AppStorage("defaultViewMode") private var defaultViewModeRaw = ViewMode.createdByMe.rawValue
    @AppStorage("defaultTab") private var defaultTabRaw = DefaultTab.favorites.rawValue
    @AppStorage("refreshInterval") private var refreshIntervalRaw = RefreshInterval.fifteenMinutes.rawValue
    @AppStorage("showCompletedItems") private var showCompletedItems = true
    @AppStorage("showCanceledItems") private var showCanceledItems = false
    @AppStorage("launchAtLogin") private var launchAtLogin = false

    @State private var showingCoffee = false

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

                    // SUPPORT
                    Section {
                        buyMeCoffeeButton
                    } header: {
                        sectionHeader(icon: "cup.and.saucer.fill", title: "Support", gradient: [.brown, .orange])
                    }

                    // ABOUT
                    Section {
                        aboutInfo
                    } header: {
                        sectionHeader(icon: "info.circle.fill", title: "About", gradient: [.gray, .secondary])
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
        .sheet(isPresented: $showingCoffee) {
            CoffeeView()
        }
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

            Picker("", selection: defaultTab) {
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

            Text("Automatically start LinearBar when you log in")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Support Section

    private var buyMeCoffeeButton: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: {
                showingCoffee = true
            }) {
                HStack {
                    Image(systemName: "cup.and.saucer.fill")
                        .foregroundColor(.orange)
                    Text("Buy Me Coffee")
                }
            }

            Text("Support LinearBar development")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - About Section

    private var aboutInfo: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Made with love by Strategic Nerds, Inc.")
                .font(.body)
                .foregroundColor(.primary)

            Text("© \(Calendar.current.component(.year, from: Date())) Strategic Nerds, Inc.")
                .font(.caption)
                .foregroundColor(.secondary)

            if let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                Text("Build \(buildNumber)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Button(action: {
                if let url = URL(string: "https://github.com/coolasspuppy/linear-bar") {
                    NSWorkspace.shared.open(url)
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "link")
                        .font(.system(size: 10))
                    Text("Contribute on GitHub")
                        .font(.caption)
                }
            }
            .buttonStyle(.link)
        }
    }
}

// MARK: - Color Picker View

struct ColorPickerView: View {
    let account: LinearAccount
    @Binding var isPresented: Bool
    @State private var hexInput: String = ""
    @State private var showInvalidHexError: Bool = false

    private let availableColors: [String] = [
        "#5E6AD2", // Linear purple
        "#10B981", // green
        "#F59E0B", // orange
        "#EF4444", // red
        "#3B82F6", // blue
        "#000000", // black
        "#EC4899", // pink
        "#8B4513"  // brown
    ]

    var body: some View {
        VStack(spacing: 20) {
            Text("Choose Account Color")
                .font(.headline)
                .padding(.top, 8)

            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    ForEach(availableColors.prefix(4), id: \.self) { colorHex in
                        colorButton(colorHex)
                    }
                }

                HStack(spacing: 16) {
                    ForEach(availableColors.suffix(4), id: \.self) { colorHex in
                        colorButton(colorHex)
                    }
                }
            }
            .padding(.horizontal, 16)

            Divider()
                .padding(.horizontal, 16)

            VStack(spacing: 8) {
                Text("Or enter a hex code:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(spacing: 8) {
                    TextField("#5E6AD2", text: $hexInput)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                        .frame(width: 140)
                        .onSubmit {
                            applyCustomHex()
                        }

                    Button("Apply") {
                        applyCustomHex()
                    }
                    .buttonStyle(.borderedProminent)
                }

                if showInvalidHexError {
                    Text("Invalid hex code")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }

            Button("Cancel") {
                closeWindow()
            }
            .buttonStyle(.bordered)
            .padding(.bottom, 8)
        }
        .frame(width: 340, height: 360)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func colorButton(_ colorHex: String) -> some View {
        Button(action: {
            AppSettings.shared.setAccountColor(colorHex, forAccount: account.email)
            closeWindow()
        }) {
            Circle()
                .fill(Color(hex: colorHex))
                .frame(width: 50, height: 50)
                .overlay(
                    Circle()
                        .stroke(account.color == colorHex ? Color.primary : Color.clear, lineWidth: 3)
                )
        }
        .buttonStyle(.plain)
    }

    private func applyCustomHex() {
        var cleanedHex = hexInput.trimmingCharacters(in: .whitespaces).uppercased()

        // Add # if missing
        if !cleanedHex.hasPrefix("#") {
            cleanedHex = "#" + cleanedHex
        }

        // Validate hex format
        let hexPattern = "^#[0-9A-F]{6}$"
        let regex = try? NSRegularExpression(pattern: hexPattern)
        let range = NSRange(location: 0, length: cleanedHex.utf16.count)

        if regex?.firstMatch(in: cleanedHex, range: range) != nil {
            AppSettings.shared.setAccountColor(cleanedHex, forAccount: account.email)
            showInvalidHexError = false
            closeWindow()
        } else {
            showInvalidHexError = true
        }
    }

    private func closeWindow() {
        isPresented = false
        NSApplication.shared.keyWindow?.close()
    }
}
