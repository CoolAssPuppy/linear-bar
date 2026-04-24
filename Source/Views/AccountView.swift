//  AccountView.swift
//  Linear Bar
//  Copyright (c) 2026 Strategic Nerds. All rights reserved.

import SwiftUI
import AppKit

/// Per-workspace detail view, shown on the right of the main window when a
/// Linear workspace is selected in the sidebar.
struct LinearAccountView: View {
    @ObservedObject private var settings = AppSettings.shared
    @Environment(\.theme) private var theme
    @State var account: LinearAccount
    @State private var displayNameDraft: String
    @State private var colorHexDraft: String
    @State private var showingDeleteAlert = false
    @State private var teams: [Team] = []
    @State private var teamsLoading: Bool = false
    @State private var lastSyncedAt: Date?
    @FocusState private var nameFieldFocused: Bool
    @FocusState private var hexFieldFocused: Bool

    init(account: LinearAccount) {
        self._account = State(initialValue: account)
        self._displayNameDraft = State(initialValue: account.name ?? "")
        self._colorHexDraft = State(initialValue: account.color ?? "#5E6AD2")
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                // Single column. A two-column layout at the default window
                // width (~820pt content area) gave each card ~370pt and the
                // AppSettingRow descriptions wrapped character-by-character.
                // Stacking is less dense but actually readable.
                VStack(alignment: .leading, spacing: 18) {
                    identityCard
                    teamsCard
                    notificationsCard
                    managementCard
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 28)
                .padding(.vertical, 24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.background)
        .onAppear { loadTeamsIfNeeded(force: false) }
        .onReceive(NotificationCenter.default.publisher(for: .accountsDidUpdate)) { _ in
            if let fresh = settings.account(forEmail: account.email) {
                account = fresh
                if !nameFieldFocused {
                    displayNameDraft = fresh.name ?? ""
                }
                if !hexFieldFocused {
                    colorHexDraft = fresh.color ?? "#5E6AD2"
                }
            }
        }
        .onChange(of: nameFieldFocused) { _, focused in
            if !focused { commitDisplayName() }
        }
        .onChange(of: hexFieldFocused) { _, focused in
            if !focused { commitColorHex() }
        }
        .alert("Remove workspace?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) {
                settings.removeAccount(account)
            }
        } message: {
            Text("This removes \(account.displayName) from Menu Bar for Linear along with all stored tokens.")
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center, spacing: 14) {
            WorkspaceLogo(account: account, size: 38)
                .overlay(
                    RoundedRectangle(cornerRadius: 38 * 0.22, style: .continuous)
                        .strokeBorder(theme.borderStrong, lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(account.displayName)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(theme.foreground)

                headerMeta
            }

            Spacer(minLength: 12)

            headerActions
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 18)
        .overlay(
            Rectangle()
                .fill(theme.divider)
                .frame(height: 1),
            alignment: .bottom
        )
    }

    @ViewBuilder
    private var headerMeta: some View {
        HStack(spacing: 10) {
            Text(workspaceURLString)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(theme.muted)

            dot

            statusBadge

            if let last = lastSyncedAt {
                dot
                Text("Synced \(relativeLabel(for: last))")
                    .font(.system(size: 11))
                    .foregroundStyle(theme.muted)
            } else if !account.email.isEmpty {
                dot
                Text(account.email)
                    .font(.system(size: 11))
                    .foregroundStyle(theme.muted)
                    .textSelection(.enabled)
            }
        }
    }

    private var dot: some View {
        Circle()
            .fill(theme.dim)
            .frame(width: 3, height: 3)
    }

    @ViewBuilder
    private var statusBadge: some View {
        if !account.isEnabled {
            statusLabel(color: theme.muted, label: "Disabled")
        } else if account.authStatus != .valid {
            statusLabel(color: theme.destructive, label: "Sign in required")
        } else {
            statusLabel(color: theme.success, label: "Connected")
        }
    }

    private func statusLabel(color: Color, label: String) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
                .shadow(color: color.opacity(0.5), radius: 4)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(color)
        }
    }

    private var headerActions: some View {
        HStack(spacing: 4) {
            AppIconButton(systemName: "arrow.triangle.2.circlepath",
                          help: "Refresh this workspace",
                          spinOnTap: true) {
                refreshWorkspace()
            }
            AppIconButton(systemName: "arrow.up.forward.app",
                          help: "Open in Linear") {
                openInLinear()
            }
        }
    }

    // MARK: - Identity card

    private var identityCard: some View {
        AppCard("Identity") {
            VStack(spacing: 0) {
                AppSettingRow(
                    "Display name",
                    description: "Shown in the sidebar, menu bar, and notifications."
                ) {
                    TextField("Your name or workspace label", text: $displayNameDraft)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                        .foregroundStyle(theme.foreground)
                        .focused($nameFieldFocused)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                                .fill(theme.cardInset)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                                .strokeBorder(theme.borderStrong, lineWidth: 1)
                        )
                        .frame(width: 240)
                        .onSubmit { commitDisplayName() }
                }

                AppRowDivider().padding(.vertical, 12)

                AppSettingRow(
                    "Accent color",
                    description: "Used for the sidebar dot and workspace marker."
                ) {
                    VStack(alignment: .trailing, spacing: 8) {
                        HStack(spacing: 8) {
                            ForEach(Self.presetColors, id: \.self) { hex in
                                colorSwatch(hex: hex)
                            }
                        }

                        TextField("#5E6AD2", text: $colorHexDraft)
                            .textFieldStyle(.plain)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(theme.foreground)
                            .focused($hexFieldFocused)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                                    .fill(theme.cardInset)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                                    .strokeBorder(theme.borderStrong, lineWidth: 1)
                            )
                            .frame(width: 140)
                            .onSubmit { commitColorHex() }
                    }
                }

                AppRowDivider().padding(.vertical, 12)

                AppSettingRow("Workspace URL") {
                    HStack(spacing: 6) {
                        Text(workspaceURLString)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(theme.muted)
                            .textSelection(.enabled)
                        AppIconButton(systemName: "doc.on.doc", help: "Copy URL") {
                            NSPasteboard.copyString(workspaceURLString)
                        }
                    }
                }
            }
        }
    }

    private static let presetColors: [String] = [
        "#5E6AD2",
        "#10B981",
        "#F59E0B",
        "#EF4444",
        "#3B82F6",
        "#EC4899"
    ]

    private func colorSwatch(hex: String) -> some View {
        Button(action: {
            colorHexDraft = hex
            commitColorHex()
        }) {
            Circle()
                .fill(Color(hex: hex))
                .frame(width: 20, height: 20)
                .overlay(
                    Circle().strokeBorder(
                        (account.color ?? "").uppercased() == hex.uppercased() ? theme.foreground : theme.borderStrong,
                        lineWidth: (account.color ?? "").uppercased() == hex.uppercased() ? 2 : 1
                    )
                )
        }
        .buttonStyle(.plain)
        .help(hex)
    }

    // MARK: - Teams card

    private var teamsCard: some View {
        AppCard("Teams") {
            if teamsLoading && teams.isEmpty {
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text("Loading teams…")
                        .font(.system(size: 11))
                        .foregroundStyle(theme.muted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else if teams.isEmpty {
                Text("No teams available. Try refreshing this workspace.")
                    .font(.system(size: 11))
                    .foregroundStyle(theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(teams.enumerated()), id: \.element.id) { index, team in
                        teamRow(team)
                        if index < teams.count - 1 {
                            AppRowDivider().padding(.vertical, 8)
                        }
                    }
                }
            }
        }
    }

    private func teamRow(_ team: Team) -> some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(theme.primary.opacity(0.15))
                .frame(width: 22, height: 22)
                .overlay(
                    Text(team.key.prefix(2).uppercased())
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(theme.primary)
                )

            VStack(alignment: .leading, spacing: 1) {
                Text(team.name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(theme.foreground)
                Text(team.key)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(theme.tertiary)
            }

            Spacer()

            if settings.selectedTeamId == team.id {
                Text("Default")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(theme.primary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(theme.primary.opacity(0.15)))
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            settings.selectedTeamId = team.id
            settings.selectedTeamKey = team.key
        }
    }

    // MARK: - Notifications card

    private var notificationsCard: some View {
        AppCard("Notifications") {
            VStack(spacing: 0) {
                AppSettingRow(
                    "Refresh interval",
                    description: "How often Menu Bar for Linear checks this workspace for new data."
                ) {
                    Picker("", selection: Binding(
                        get: { settings.refreshInterval },
                        set: { settings.refreshInterval = $0 }
                    )) {
                        ForEach(RefreshInterval.allCases) { interval in
                            Text(interval.rawValue).tag(interval)
                        }
                    }
                    .pickerStyle(.menu)
                    .appBoxedPicker()
                }

                AppRowDivider().padding(.vertical, 12)

                AppSettingRow(
                    "Show completed items",
                    description: "Display items that have been marked as done."
                ) {
                    Toggle("", isOn: Binding(
                        get: { settings.showCompletedItems },
                        set: { settings.showCompletedItems = $0 }
                    ))
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .tint(theme.primary)
                }

                AppRowDivider().padding(.vertical, 12)

                AppSettingRow(
                    "Show canceled items",
                    description: "Display items that have been canceled."
                ) {
                    Toggle("", isOn: Binding(
                        get: { settings.showCanceledItems },
                        set: { settings.showCanceledItems = $0 }
                    ))
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .tint(theme.primary)
                }
            }
        }
    }

    // MARK: - Management card

    private var managementCard: some View {
        AppCard("Workspace Management") {
            VStack(spacing: 0) {
                AppSettingRow(
                    "Enable this workspace",
                    description: "When off, Menu Bar for Linear will not sync or surface this workspace."
                ) {
                    Toggle("", isOn: Binding(
                        get: { account.isEnabled },
                        set: { newValue in
                            account.isEnabled = newValue
                            settings.updateAccount(account)
                        }
                    ))
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .tint(theme.primary)
                }

                AppRowDivider().padding(.vertical, 12)

                AppSettingRow(
                    "Reauthorize",
                    description: "Sign in again to refresh OAuth tokens."
                ) {
                    AppSecondaryButton(title: "Sign in again",
                                       systemImage: "arrow.triangle.2.circlepath") {
                        reauthorize()
                    }
                }

                AppRowDivider().padding(.vertical, 12)

                AppSettingRow(
                    "Remove workspace",
                    description: "Deletes the workspace and all stored tokens. This is permanent."
                ) {
                    AppSecondaryButton(title: "Remove workspace",
                                       systemImage: "trash",
                                       tint: .destructive) {
                        showingDeleteAlert = true
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private var workspaceURLString: String {
        if let slug = account.organizationSlug, !slug.isEmpty {
            return "\(slug).linear.app"
        }
        return "linear.app"
    }

    private func relativeLabel(for date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        if seconds < 60 { return "just now" }
        if seconds < 3600 { return "\(seconds / 60)m ago" }
        if seconds < 86400 { return "\(seconds / 3600)h ago" }
        return "\(seconds / 86400)d ago"
    }

    private func commitDisplayName() {
        let trimmed = displayNameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let newValue: String? = trimmed.isEmpty ? nil : trimmed
        guard newValue != account.name else { return }
        account.name = newValue
        settings.updateAccount(account)
    }

    private static let hexColorRegex = try? NSRegularExpression(pattern: "^#[0-9A-F]{6}$")

    private func commitColorHex() {
        var cleaned = colorHexDraft.trimmingCharacters(in: .whitespaces).uppercased()
        if !cleaned.hasPrefix("#") {
            cleaned = "#" + cleaned
        }
        let range = NSRange(location: 0, length: cleaned.utf16.count)
        guard Self.hexColorRegex?.firstMatch(in: cleaned, range: range) != nil else {
            colorHexDraft = account.color ?? "#5E6AD2"
            return
        }
        guard cleaned != (account.color ?? "").uppercased() else {
            colorHexDraft = cleaned
            return
        }
        account.color = cleaned
        colorHexDraft = cleaned
        settings.setAccountColor(cleaned, forAccount: account.email)
    }

    private func refreshWorkspace() {
        lastSyncedAt = Date()
        NotificationCenter.default.post(name: .refreshAllData, object: nil)
        loadTeamsIfNeeded(force: true)
    }

    private func openInLinear() {
        if let slug = account.organizationSlug, !slug.isEmpty {
            guard let url = SafeExternalURL.linearURL(orgSlug: slug, pathComponents: []) else { return }
            NSWorkspace.shared.open(url)
            return
        }

        guard let fallback = SafeExternalURL.linearURL(from: "https://linear.app") else { return }
        NSWorkspace.shared.open(fallback)
    }

    private func reauthorize() {
        LinearAuthService.shared.addLinearAccount { result in
            Task { @MainActor in
                if case .failure(let error) = result {
                    let alert = NSAlert()
                    alert.messageText = "Sign-in failed"
                    alert.informativeText = error.localizedDescription
                    alert.alertStyle = .warning
                    alert.runModal()
                }
            }
        }
    }

    private func loadTeamsIfNeeded(force: Bool) {
        guard account.authStatus == .valid else { return }
        if !force, !teams.isEmpty { return }
        guard let token = KeychainService.shared.retrieveAccessToken(forAccount: account.email) else {
            return
        }
        teamsLoading = true
        Task { @MainActor in
            defer { teamsLoading = false }
            do {
                let fetched = try await LinearAPI.shared.fetchTeams(
                    accessToken: token,
                    accountEmail: account.email
                )
                self.teams = fetched
                self.lastSyncedAt = Date()
            } catch {
                AppLogger.error("Failed to load teams for account",
                                log: AppLogger.app, error: error)
            }
        }
    }
}

#Preview {
    LinearAccountView(account: .preview)
        .frame(width: 860, height: 600)
}
