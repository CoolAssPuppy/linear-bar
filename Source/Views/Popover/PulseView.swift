import SwiftUI

/// Pulse tab. One compact card per team with an active cycle, plus a
/// shared "Threatening the cycle" list built from at-risk issues across
/// every team shown. Respects the team filter chip — selecting a single
/// team collapses to that team's card + at-risk list.
/// See Paper artboard "Popover - Pulse".
struct PulseView: View {
    @State private var bundles: [ActiveCycleBundle] = []
    @State private var atRisk: [CycleIssue] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var hasLoadedOnce = false

    @ObservedObject private var teamsStore = TeamsStore.shared
    @ObservedObject private var settings = AppSettings.shared
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 0) {
            subHeader

            Group {
                if isLoading && bundles.isEmpty {
                    LoadingStateView("Loading cycles…")
                } else if AppSettings.shared.accounts.isEmpty {
                    NoAccountView(message: "Connect your Linear account to see cycle health.")
                } else if let error = errorMessage {
                    ErrorStateView(title: "Could not load cycles", message: error, onRetry: loadData)
                } else if bundles.isEmpty {
                    EmptyStateView(
                        icon: "waveform.path.ecg",
                        title: "No active cycles",
                        subtitle: "None of your teams have an active cycle right now."
                    )
                } else {
                    contentView
                }
            }
        }
        .onAppear {
            teamsStore.loadIfNeeded()
            if !hasLoadedOnce {
                hasLoadedOnce = true
                loadData()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .teamFilterChanged)) { _ in
            loadData()
        }
        .onReceive(NotificationCenter.default.publisher(for: .refreshAllData)) { _ in
            loadData()
        }
    }

    // MARK: - Sub-header

    private var subHeader: some View {
        HStack(spacing: 8) {
            PopoverTeamChip()
            Spacer(minLength: 0)
            liveIndicator
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var liveIndicator: some View {
        HStack(spacing: 5) {
            Circle().fill(theme.success).frame(width: 6, height: 6)
            Text("Live")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(theme.tertiary)
        }
    }

    // MARK: - Content

    private var contentView: some View {
        ScrollView {
            VStack(spacing: 0) {
                VStack(spacing: 10) {
                    ForEach(bundles, id: \.teamId) { bundle in
                        if let cycle = bundle.cycle {
                            CycleCard(team: bundle, cycle: cycle)
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 4)
                .padding(.bottom, 10)

                if !atRisk.isEmpty {
                    PopoverSectionDivider(label: "Threatening the cycle", count: atRisk.count)

                    LazyVStack(spacing: 0) {
                        ForEach(atRisk) { issue in
                            CompactIssueRow(cycleIssue: issue)
                        }
                    }
                }

                Spacer(minLength: 8)
            }
        }
    }

    // MARK: - Data

    private func loadData() {
        let session: PopoverSession
        do {
            session = try PopoverSession.resolve()
        } catch {
            errorMessage = error.localizedDescription
            return
        }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                try await performFetch(session: session)
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }

    private func performFetch(session: PopoverSession) async throws {
        let teams: [Team]
        if teamsStore.teams.isEmpty {
            teams = try await LinearAPI.shared.fetchTeams(
                accessToken: session.accessToken,
                accountEmail: session.accountEmail
            )
        } else {
            teams = teamsStore.teams
        }

        // Respect the shared team filter. Nil means "all teams" — fetch
        // every team's active cycle in parallel.
        let targetTeams: [Team]
        if let pinned = settings.selectedTeamId,
           let match = teams.first(where: { $0.id == pinned }) {
            targetTeams = [match]
        } else {
            targetTeams = teams
        }

        guard !targetTeams.isEmpty else {
            await MainActor.run {
                bundles = []
                atRisk = []
                isLoading = false
                errorMessage = "No teams available on this account."
            }
            return
        }

        let fetched = await fetchBundles(targetTeams: targetTeams, session: session)
        let active = fetched.filter { $0.cycle != nil }

        // Interleave at-risk issues across every active cycle, ranked by
        // risk reason severity. SLA breaches surface above stale-3d
        // regardless of which team owns them.
        let ranked = active
            .flatMap { $0.cycle?.issues.nodes ?? [] }
            .filter { $0.state?.isOpen ?? true }
            .sorted { $0.riskReason.severity < $1.riskReason.severity }

        await MainActor.run {
            bundles = active
            atRisk = ranked
            isLoading = false
        }
    }

    /// Kicks off `fetchActiveCycleWithIssues` for every team concurrently
    /// and gathers the bundles. Failures for individual teams are swallowed
    /// so one bad team doesn't blank the whole tab.
    private func fetchBundles(targetTeams: [Team], session: PopoverSession) async -> [ActiveCycleBundle] {
        await withTaskGroup(of: ActiveCycleBundle?.self) { group in
            for team in targetTeams {
                group.addTask {
                    try? await LinearAPI.shared.fetchActiveCycleWithIssues(
                        teamId: team.id,
                        accessToken: session.accessToken,
                        accountEmail: session.accountEmail
                    )
                }
            }
            var result: [ActiveCycleBundle] = []
            for await bundle in group {
                if let bundle { result.append(bundle) }
            }
            // Stable display order: match the original team list so the UI
            // doesn't reshuffle on every load based on network race.
            return result.sorted { lhs, rhs in
                let lhsIndex = targetTeams.firstIndex(where: { $0.id == lhs.teamId }) ?? .max
                let rhsIndex = targetTeams.firstIndex(where: { $0.id == rhs.teamId }) ?? .max
                return lhsIndex < rhsIndex
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
            RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous).fill(theme.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous).strokeBorder(theme.border, lineWidth: 1)
        )
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(team.teamName)
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.3)
                .textCase(.uppercase)
                .foregroundStyle(theme.tertiary)
            Text(cycleTitle)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(theme.foreground)
            Spacer(minLength: 0)
            Text(cycle.pace.label)
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
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(theme.muted)
        }
    }

    private var cycleTitle: String {
        if let name = cycle.name, !name.isEmpty { return name }
        return "Cycle \(cycle.number)"
    }

    private var paceColor: Color {
        switch cycle.pace {
        case .behind:               return theme.warning
        case .onTrack, .done:       return theme.success
        case .starting:             return theme.muted
        }
    }

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
                Rectangle().fill(theme.success).frame(width: width * CGFloat(done / total))
                Rectangle().fill(theme.primary).frame(width: width * CGFloat(inProgress / total))
                Rectangle().fill(theme.border)
            }
            .frame(height: 6)
            .clipShape(Capsule())
        }
        .frame(height: 6)
    }
}
