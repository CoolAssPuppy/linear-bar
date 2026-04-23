import SwiftUI

/// Pulse tab. Renders one cycle card (progress, pace, scope delta) plus a
/// list of issues threatening that cycle, ranked by risk reason. Scoped to
/// a single team because cycles are per-team. See Paper artboard
/// "Popover - Pulse".
struct PulseView: View {
    @State private var bundle: ActiveCycleBundle?
    @State private var availableTeams: [Team] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var hasLoadedOnce = false

    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 0) {
            subHeader

            Group {
                if isLoading && bundle == nil {
                    LoadingStateView("Loading cycle…")
                } else if AppSettings.shared.accounts.isEmpty {
                    NoAccountView(message: "Connect your Linear account to see cycle health.")
                } else if let error = errorMessage {
                    ErrorStateView(title: "Could not load cycle", message: error, onRetry: loadData)
                } else if let bundle, let cycle = bundle.cycle {
                    contentView(team: bundle, cycle: cycle)
                } else {
                    EmptyStateView(
                        icon: "waveform.path.ecg",
                        title: "No active cycle",
                        subtitle: "This team does not have cycles enabled, or there is no active cycle right now."
                    )
                }
            }
        }
        .onAppear {
            if !hasLoadedOnce {
                hasLoadedOnce = true
                loadData()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .refreshAllData)) { _ in
            loadData()
        }
    }

    // MARK: - Sub-header

    private var subHeader: some View {
        HStack(spacing: 8) {
            PulseTeamChip(selectedTeam: selectedTeam, teams: availableTeams, onSelect: selectTeam)
            Spacer(minLength: 0)
            liveIndicator
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var liveIndicator: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(theme.success)
                .frame(width: 6, height: 6)
            Text("Live")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(theme.tertiary)
        }
    }

    // MARK: - Content

    private func contentView(team: ActiveCycleBundle, cycle: LinearCycle) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                CycleCard(team: team, cycle: cycle)
                    .padding(.horizontal, 14)
                    .padding(.top, 4)
                    .padding(.bottom, 10)

                atRiskSection(cycle: cycle)

                Spacer(minLength: 8)
            }
        }
    }

    private func atRiskSection(cycle: LinearCycle) -> some View {
        let atRisk = cycle.issues.nodes.sorted { $0.riskReason.severity < $1.riskReason.severity }

        return VStack(spacing: 0) {
            HStack(spacing: 10) {
                Text("THREATENING THE CYCLE")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.8)
                    .foregroundStyle(theme.tertiary)
                Rectangle().fill(theme.divider).frame(height: 1)
                Text("\(atRisk.count)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(theme.tertiary)
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 4)

            LazyVStack(spacing: 0) {
                ForEach(atRisk) { issue in
                    CompactIssueRow(cycleIssue: issue)
                }
            }
        }
    }

    // MARK: - Data

    private var selectedTeam: Team? {
        guard let teamId = bundle?.teamId else {
            return availableTeams.first(where: { $0.id == AppSettings.shared.selectedTeamId })
                ?? availableTeams.first
        }
        return availableTeams.first(where: { $0.id == teamId })
            ?? Team(id: bundle?.teamId ?? "",
                    name: bundle?.teamName ?? "",
                    key: bundle?.teamKey ?? "",
                    icon: nil)
    }

    private func selectTeam(_ team: Team) {
        AppSettings.shared.selectedTeamId = team.id
        AppSettings.shared.selectedTeamKey = team.key
        loadData()
    }

    private func loadData() {
        let accessToken: String
        let accountEmail: String

        if TestDataProvider.isUITesting {
            accessToken = "demo-token"
            accountEmail = "demo@example.com"
        } else {
            guard let account = AppSettings.shared.accounts.first(where: { $0.isEnabled && $0.authStatus == .valid }),
                  let token = KeychainService.shared.retrieveAccessToken(forAccount: account.email) else {
                errorMessage = "No authenticated account found. Please sign in."
                return
            }
            accessToken = token
            accountEmail = account.email
        }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                // Fetch the team list first when we don't have one — the
                // picker needs it regardless of whether the fetch succeeds.
                let teams: [Team]
                if availableTeams.isEmpty {
                    teams = try await LinearAPI.shared.fetchTeams(accessToken: accessToken, accountEmail: accountEmail)
                } else {
                    teams = availableTeams
                }

                let targetTeamId = AppSettings.shared.selectedTeamId
                    ?? teams.first?.id
                    ?? ""

                guard !targetTeamId.isEmpty else {
                    await MainActor.run {
                        availableTeams = teams
                        isLoading = false
                        errorMessage = "No teams available on this account."
                    }
                    return
                }

                let cycleBundle = try await LinearAPI.shared.fetchActiveCycleWithIssues(
                    teamId: targetTeamId,
                    accessToken: accessToken,
                    accountEmail: accountEmail
                )

                await MainActor.run {
                    availableTeams = teams
                    bundle = cycleBundle
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Cycle card

private struct CycleCard: View {
    let team: ActiveCycleBundle
    let cycle: LinearCycle

    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            numbersRow
            ProgressBar(cycle: cycle)
            legend
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                .fill(theme.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                .strokeBorder(theme.border, lineWidth: 1)
        )
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(cycleTitle)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(theme.foreground)
            Text(dateRangeLabel)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(theme.tertiary)
            Spacer(minLength: 0)
            Text(cycle.paceLabel)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(paceColor)
        }
    }

    private var numbersRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text("\(Int(round(cycle.progress * 100)))")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundStyle(theme.foreground)
                    .kerning(-0.5)
                Text("%")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(theme.muted)
            }

            statBlock(title: "DAYS LEFT", value: "\(cycle.daysLeft)", tint: theme.foreground)

            if let delta = cycle.scopeDeltaFraction {
                let sign = delta >= 0 ? "+" : ""
                let percent = Int(round(delta * 100))
                let tint: Color = delta > 0.05 ? theme.destructive : theme.success
                statBlock(title: "SCOPE Δ", value: "\(sign)\(percent)%", tint: tint)
            }

            Spacer(minLength: 0)
        }
    }

    private func statBlock(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 9, weight: .semibold))
                .tracking(0.6)
                .foregroundStyle(theme.tertiary)
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(tint)
        }
    }

    private var legend: some View {
        HStack(spacing: 12) {
            legendDot(color: theme.success, label: "\(counts.done) done")
            legendDot(color: theme.primary, label: "\(counts.inProgress) in progress")
            legendDot(color: theme.border, label: "\(counts.open) open")
        }
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(theme.muted)
        }
    }

    // MARK: - Helpers

    private var cycleTitle: String {
        if let name = cycle.name, !name.isEmpty { return name }
        return "\(team.teamKey) Cycle \(cycle.number)"
    }

    private var dateRangeLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: cycle.startsAt)) to \(formatter.string(from: cycle.endsAt))"
    }

    private var paceColor: Color {
        switch cycle.paceLabel {
        case "Behind pace": return theme.warning
        case "On pace":     return theme.success
        case "Done":        return theme.success
        default:            return theme.muted
        }
    }

    /// Collapses the per-day scope arrays into three current counts. We use
    /// the last sample of `completedScopeHistory` and `inProgressScopeHistory`,
    /// then derive "open" as total scope minus those two buckets.
    private var counts: (done: Int, inProgress: Int, open: Int) {
        let done = Int(cycle.completedScopeHistory.last ?? 0)
        let inProgress = Int(cycle.inProgressScopeHistory.last ?? 0)
        let total = Int(cycle.scopeHistory.last ?? 0)
        let open = max(total - done - inProgress, 0)
        return (done, inProgress, open)
    }
}

// MARK: - Segmented progress bar

private struct ProgressBar: View {
    let cycle: LinearCycle

    @Environment(\.theme) private var theme

    var body: some View {
        GeometryReader { proxy in
            let total = max(cycle.scopeHistory.last ?? 0, 1)
            let done = cycle.completedScopeHistory.last ?? 0
            let inProgress = cycle.inProgressScopeHistory.last ?? 0
            let width = proxy.size.width

            HStack(spacing: 0) {
                Rectangle()
                    .fill(theme.success)
                    .frame(width: width * CGFloat(done / total))
                Rectangle()
                    .fill(theme.primary)
                    .frame(width: width * CGFloat(inProgress / total))
                Rectangle()
                    .fill(theme.border)
            }
            .frame(height: 6)
            .clipShape(Capsule())
        }
        .frame(height: 6)
    }
}

// MARK: - Team chip (Pulse)

private struct PulseTeamChip: View {
    let selectedTeam: Team?
    let teams: [Team]
    let onSelect: (Team) -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        Menu {
            ForEach(teams) { team in
                Button(action: { onSelect(team) }) {
                    HStack {
                        Text(team.name)
                        if team.id == selectedTeam?.id {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 5) {
                Text(selectedTeam?.name ?? "Pick a team")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(theme.foreground)
                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(theme.tertiary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
    }
}
