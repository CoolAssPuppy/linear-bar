import SwiftUI
import ObjectiveC

/// Tab view for managing Linear accounts
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

            #if DEBUG
            if settings.accounts.isEmpty {
                demoDataLink
            }
            #endif

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

    // MARK: - Empty State

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

    // MARK: - Account List

    private var accountListView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Connected Accounts")
                .font(.headline)

            ScrollView {
                VStack(spacing: 8) {
                    ForEach(settings.accounts) { account in
                        AccountRowView(
                            account: account,
                            onColorTap: {
                                selectedAccount = account
                                showingColorPicker = true
                            },
                            onRemove: { removeAccount(account) },
                            onReconnect: { reconnectAccount(account) }
                        )
                    }
                }
            }
        }
    }

    // MARK: - Buttons

    #if DEBUG
    private var demoDataLink: some View {
        Button(action: {
            TestDataProvider.enableDemoMode()
        }) {
            Text("View Demo Data")
                .font(.system(size: 11))
                .foregroundColor(.blue)
        }
        .buttonStyle(.plain)
        .padding(.bottom, 8)
    }
    #endif

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

    // MARK: - Actions

    private func addLinearAccount() {
        LinearAuthService.shared.addLinearAccount { result in
            Task { @MainActor in
                if case .failure(let error) = result {
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
                if case .failure(let error) = result {
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

        objc_setAssociatedObject(self, "colorPickerWindow", window, .OBJC_ASSOCIATION_RETAIN)
    }
}

// MARK: - Account Row View

private struct AccountRowView: View {
    let account: LinearAccount
    let onColorTap: () -> Void
    let onRemove: () -> Void
    let onReconnect: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Button(action: onColorTap) {
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

                Button("Remove", action: onRemove)
                    .buttonStyle(.borderless)
                    .foregroundColor(.red)
            }

            if account.authStatus != .valid {
                authWarningView
            }
        }
        .padding(12)
        .background(account.authStatus != .valid ? Color.orange.opacity(0.1) : Color(nsColor: .controlBackgroundColor).opacity(0.5))
        .cornerRadius(6)
    }

    private var authWarningView: some View {
        VStack {
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

                Button("Sign In", action: onReconnect)
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .controlSize(.small)
            }
        }
    }
}
