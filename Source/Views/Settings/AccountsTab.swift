import SwiftUI
import ObjectiveC

/// Tab view for managing Linear accounts
struct AccountsTab: View {
    @ObservedObject private var settings = AppSettings.shared
    @State private var accountToRemove: LinearAccount?
    @State private var showingRemoveAlert = false
    @State private var showingColorPicker = false
    @State private var selectedAccount: LinearAccount?

    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 16) {
            if settings.accounts.isEmpty {
                emptyStateView
            } else {
                accountListView
            }

            Spacer()

            if settings.accounts.isEmpty {
                demoDataLink
            }

            addAccountButton
        }
        .padding(20)
        .background(theme.background)
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
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(theme.card)
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.system(size: 22, weight: .light))
                    .foregroundStyle(theme.muted)
            }
            .frame(width: 56, height: 56)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(theme.border, lineWidth: 1)
            )

            Text("No accounts connected")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(theme.foreground)

            Text("Add a Linear account to get started")
                .font(.system(size: 11))
                .foregroundStyle(theme.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Account List

    private var accountListView: some View {
        AppCard("Connected Accounts") {
            VStack(spacing: 0) {
                ForEach(Array(settings.accounts.enumerated()), id: \.element.id) { index, account in
                    AccountRowView(
                        account: account,
                        onColorTap: {
                            selectedAccount = account
                            showingColorPicker = true
                        },
                        onRemove: { removeAccount(account) },
                        onReconnect: { reconnectAccount(account) }
                    )
                    if index < settings.accounts.count - 1 {
                        AppRowDivider()
                    }
                }
            }
        }
    }

    // MARK: - Buttons

    private var demoDataLink: some View {
        Button(action: {
            TestDataProvider.enableDemoMode()
        }) {
            Text("View Demo Data")
                .font(.system(size: 11))
                .foregroundStyle(theme.primary)
        }
        .buttonStyle(.plain)
        .padding(.bottom, 8)
    }

    private var addAccountButton: some View {
        AppSecondaryButton(title: "Add Linear Account", systemImage: "plus.circle.fill", tint: .primary, action: addLinearAccount)
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

    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Button(action: onColorTap) {
                    Circle()
                        .fill(Color(hex: account.color ?? "#5E6AD2"))
                        .frame(width: 20, height: 20)
                        .overlay(
                            Circle()
                                .stroke(theme.borderStrong, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .help("Change account color")

                VStack(alignment: .leading, spacing: 4) {
                    if let name = account.name {
                        Text(name)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(theme.foreground)
                    }
                    Text(account.email)
                        .font(.system(size: 11))
                        .foregroundStyle(theme.muted)
                }

                Spacer()

                AppSecondaryButton(title: "Remove", tint: .destructive, action: onRemove)
            }
            .padding(.vertical, 8)

            if account.authStatus != .valid {
                authWarningView
            }
        }
    }

    private var authWarningView: some View {
        VStack(spacing: 0) {
            AppRowDivider()
                .padding(.vertical, 8)

            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(theme.warning)
                    .font(.system(size: 14))

                VStack(alignment: .leading, spacing: 4) {
                    Text(account.authStatus == .needsAuth ? "Sign in required" : "Authentication expired")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(theme.warning)

                    Text("Click Sign In to restore access")
                        .font(.system(size: 11))
                        .foregroundStyle(theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                AppSecondaryButton(title: "Sign In", tint: .primary, action: onReconnect)
            }
            .padding(.bottom, 8)
        }
    }
}
