import Foundation

/// Provides test data for UI testing screenshots and demo mode
/// Fictional AI Ski Goggles company with funny but professional content
struct TestDataProvider {

    /// Runtime flag to enable demo mode (set by user clicking "Demo Data" link)
    static var isDemoModeEnabled: Bool = false

    static var isUITesting: Bool {
        CommandLine.arguments.contains("--uitesting") || isDemoModeEnabled
    }

    /// Enables demo mode and sets up the test account
    @MainActor
    static func enableDemoMode() {
        isDemoModeEnabled = true

        // Create a demo account
        let demoAccount = LinearAccount(
            email: "sarah@aiskigoggles.ai",
            name: "Sarah Chen",
            organizationSlug: "aigoggles",
            isEnabled: true,
            authStatus: .valid,
            color: "#5E6AD2"
        )

        AppSettings.shared.accounts = [demoAccount]
        NotificationCenter.default.post(name: .accountsDidUpdate, object: nil)
        NotificationCenter.default.post(name: .refreshAllData, object: nil)
    }

    // MARK: - Viewer

    static func getViewer() -> Viewer {
        return Viewer(
            id: "viewer-1",
            name: "Sarah Chen",
            email: "sarah@aiskigoggles.ai",
            organization: ViewerOrganization(
                id: "org-1",
                name: "AI Ski Goggles Inc.",
                urlKey: "aigoggles",
                logoUrl: nil
            )
        )
    }


    // MARK: - Recent Issues

    static func getRecentIssues() -> [Issue] {
        let calendar = Calendar.current
        let now = Date()
        func hoursAgo(_ h: Int) -> Date? { calendar.date(byAdding: .hour, value: -h, to: now) }
        func daysAgo(_ d: Int) -> Date? { calendar.date(byAdding: .day, value: -d, to: now) }

        let winterLaunch = ProjectReference(id: "proj-1", name: "Winter 2026 Launch", icon: "🎿")
        let payments = ProjectReference(id: "proj-2", name: "Payments 2.0", icon: "💳")

        return [
            // Today — active
            Issue(
                id: "issue-1", identifier: "AG-318",
                title: "Implement \"clouds or avalanche risk?\" detection",
                description: nil,
                url: "https://linear.app/aigoggles/issue/AG-318",
                createdAt: hoursAgo(3), updatedAt: hoursAgo(0),
                dueDate: nil,
                state: IssueState(name: "In Progress", type: "started"),
                priority: 2, priorityLabel: "High",
                assignee: User(name: "Marcus Kim"),
                team: Team(id: "team-1", name: "ML Vision", key: "MLVIS", icon: "🤖"),
                labels: LabelConnection(nodes: [
                    IssueLabel(id: "label-1", name: "feature", color: "#3B82F6"),
                    IssueLabel(id: "label-2", name: "safety", color: "#EF4444")
                ]),
                project: winterLaunch, parent: nil
            ),
            Issue(
                id: "issue-2", identifier: "AG-315",
                title: "Add \"friend detection\" to stop yelling at strangers",
                description: nil,
                url: "https://linear.app/aigoggles/issue/AG-315",
                createdAt: hoursAgo(8), updatedAt: hoursAgo(1),
                dueDate: "2026-05-12",
                state: IssueState(name: "In Review", type: "started"),
                priority: 3, priorityLabel: "Medium",
                assignee: User(name: "Jordan Lee"),
                team: Team(id: "team-1", name: "ML Vision", key: "MLVIS", icon: "🤖"),
                labels: LabelConnection(nodes: [
                    IssueLabel(id: "label-3", name: "social", color: "#EC4899"),
                    IssueLabel(id: "label-4", name: "ml-training", color: "#8B5CF6")
                ]),
                project: nil, parent: nil
            ),
            // Yesterday — hardware
            Issue(
                id: "issue-3", identifier: "AG-310",
                title: "Goggles fog up when user is too excited about powder",
                description: nil,
                url: "https://linear.app/aigoggles/issue/AG-310",
                createdAt: daysAgo(1), updatedAt: hoursAgo(22),
                dueDate: "2026-05-20",
                state: IssueState(name: "Todo", type: "unstarted"),
                priority: 2, priorityLabel: "High",
                assignee: User(name: "Elena Rodriguez"),
                team: Team(id: "team-2", name: "Hardware", key: "HW", icon: "⚡"),
                labels: LabelConnection(nodes: [
                    IssueLabel(id: "label-5", name: "hardware", color: "#F59E0B"),
                    IssueLabel(id: "label-6", name: "ux", color: "#06B6D4")
                ]),
                project: winterLaunch, parent: nil
            ),
            Issue(
                id: "issue-4", identifier: "AG-307",
                title: "Battery drains 30% faster in alpine cold",
                description: nil,
                url: "https://linear.app/aigoggles/issue/AG-307",
                createdAt: daysAgo(2), updatedAt: daysAgo(1),
                dueDate: nil,
                state: IssueState(name: "In Progress", type: "started"),
                priority: 1, priorityLabel: "Urgent",
                assignee: User(name: "Elena Rodriguez"),
                team: Team(id: "team-2", name: "Hardware", key: "HW", icon: "⚡"),
                labels: LabelConnection(nodes: [
                    IssueLabel(id: "label-7", name: "hardware", color: "#F59E0B"),
                    IssueLabel(id: "label-8", name: "bug", color: "#EF4444")
                ]),
                project: winterLaunch, parent: nil
            ),
            // Last 3–5 days — product + AR
            Issue(
                id: "issue-5", identifier: "AG-298",
                title: "AR overlay shows \"You're doing great!\" even during faceplant",
                description: nil,
                url: "https://linear.app/aigoggles/issue/AG-298",
                createdAt: daysAgo(3), updatedAt: daysAgo(2),
                dueDate: "2026-05-08",
                state: IssueState(name: "In Progress", type: "started"),
                priority: 1, priorityLabel: "Urgent",
                assignee: User(name: "Alex Morgan"),
                team: Team(id: "team-4", name: "AR Experience", key: "AR", icon: "🥽"),
                labels: LabelConnection(nodes: [
                    IssueLabel(id: "label-9", name: "bug", color: "#EF4444"),
                    IssueLabel(id: "label-10", name: "ar-display", color: "#8B5CF6")
                ]),
                project: winterLaunch, parent: nil
            ),
            Issue(
                id: "issue-6", identifier: "AG-295",
                title: "Onboarding: detect left vs right goggle before first calibration",
                description: nil,
                url: "https://linear.app/aigoggles/issue/AG-295",
                createdAt: daysAgo(4), updatedAt: daysAgo(3),
                dueDate: nil,
                state: IssueState(name: "In Progress", type: "started"),
                priority: 3, priorityLabel: "Medium",
                assignee: User(name: "Rafa Patel"),
                team: Team(id: "team-3", name: "Product", key: "PROD", icon: "📱"),
                labels: LabelConnection(nodes: [
                    IssueLabel(id: "label-11", name: "onboarding", color: "#3B82F6")
                ]),
                project: nil, parent: nil
            ),
            // Completed — last week
            Issue(
                id: "issue-7", identifier: "AG-284",
                title: "Document: \"How to explain to investors why we need AI for skiing\"",
                description: nil,
                url: "https://linear.app/aigoggles/issue/AG-284",
                createdAt: daysAgo(6), updatedAt: daysAgo(5),
                dueDate: nil,
                state: IssueState(name: "Done", type: "completed"),
                priority: 4, priorityLabel: "Low",
                assignee: User(name: "Sarah Chen"),
                team: Team(id: "team-3", name: "Product", key: "PROD", icon: "📱"),
                labels: LabelConnection(nodes: [
                    IssueLabel(id: "label-12", name: "documentation", color: "#6B7280")
                ]),
                project: nil, parent: nil
            ),
            Issue(
                id: "issue-8", identifier: "AG-279",
                title: "Stripe refund retries silently dropped after timeout",
                description: nil,
                url: "https://linear.app/aigoggles/issue/AG-279",
                createdAt: daysAgo(7), updatedAt: daysAgo(6),
                dueDate: nil,
                state: IssueState(name: "Done", type: "completed"),
                priority: 2, priorityLabel: "High",
                assignee: User(name: "Sam Okafor"),
                team: Team(id: "team-3", name: "Product", key: "PROD", icon: "📱"),
                labels: LabelConnection(nodes: [
                    IssueLabel(id: "label-13", name: "payments", color: "#10B981")
                ]),
                project: payments, parent: nil
            ),
            // Older activity — 8–13 days ago
            Issue(
                id: "issue-9", identifier: "AG-268",
                title: "Voice assistant keeps mishearing \"pow\" as \"pow pow\"",
                description: nil,
                url: "https://linear.app/aigoggles/issue/AG-268",
                createdAt: daysAgo(9), updatedAt: daysAgo(8),
                dueDate: nil,
                state: IssueState(name: "Todo", type: "unstarted"),
                priority: 3, priorityLabel: "Medium",
                assignee: User(name: "Jordan Lee"),
                team: Team(id: "team-1", name: "ML Vision", key: "MLVIS", icon: "🤖"),
                labels: LabelConnection(nodes: [
                    IssueLabel(id: "label-14", name: "voice", color: "#8B5CF6")
                ]),
                project: nil, parent: nil
            ),
            Issue(
                id: "issue-10", identifier: "AG-259",
                title: "AR HUD flickers when Bluetooth reconnects mid-run",
                description: nil,
                url: "https://linear.app/aigoggles/issue/AG-259",
                createdAt: daysAgo(10), updatedAt: daysAgo(9),
                dueDate: nil,
                state: IssueState(name: "Canceled", type: "canceled"),
                priority: 3, priorityLabel: "Medium",
                assignee: User(name: "Alex Morgan"),
                team: Team(id: "team-4", name: "AR Experience", key: "AR", icon: "🥽"),
                labels: LabelConnection(nodes: [
                    IssueLabel(id: "label-15", name: "duplicate", color: "#6B7280")
                ]),
                project: nil, parent: nil
            ),
            Issue(
                id: "issue-11", identifier: "AG-248",
                title: "Cycle burndown ignores weekends in early-week math",
                description: nil,
                url: "https://linear.app/aigoggles/issue/AG-248",
                createdAt: daysAgo(12), updatedAt: daysAgo(11),
                dueDate: nil,
                state: IssueState(name: "Done", type: "completed"),
                priority: 4, priorityLabel: "Low",
                assignee: User(name: "Sarah Chen"),
                team: Team(id: "team-3", name: "Product", key: "PROD", icon: "📱"),
                labels: LabelConnection(nodes: [
                    IssueLabel(id: "label-16", name: "analytics", color: "#10B981")
                ]),
                project: nil, parent: nil
            ),
            Issue(
                id: "issue-12", identifier: "AG-236",
                title: "Add Strava integration for post-run analytics",
                description: nil,
                url: "https://linear.app/aigoggles/issue/AG-236",
                createdAt: daysAgo(13), updatedAt: daysAgo(12),
                dueDate: "2026-06-01",
                state: IssueState(name: "In Progress", type: "started"),
                priority: 3, priorityLabel: "Medium",
                assignee: User(name: "Erin Wu"),
                team: Team(id: "team-3", name: "Product", key: "PROD", icon: "📱"),
                labels: LabelConnection(nodes: [
                    IssueLabel(id: "label-17", name: "integration", color: "#3B82F6")
                ]),
                project: nil, parent: nil
            )
        ]
    }

    // MARK: - Teams

    static func getTeams() -> [Team] {
        return [
            Team(id: "team-1", name: "ML Vision", key: "MLVIS", icon: "🤖"),
            Team(id: "team-2", name: "Hardware", key: "HW", icon: "⚡"),
            Team(id: "team-3", name: "Product", key: "PROD", icon: "📱"),
            Team(id: "team-4", name: "AR Experience", key: "AR", icon: "🥽")
        ]
    }


    // MARK: - Projects

    static func getRecentProjects() -> [Project] {
        let calendar = Calendar.current
        let now = Date()

        return [
            Project(
                id: "proj-1",
                name: "Winter 2026 Launch",
                description: "Goggles v2 rollout across North America and Europe.",
                url: "https://linear.app/aigoggles/project/winter-2026",
                createdAt: calendar.date(byAdding: .month, value: -3, to: now),
                updatedAt: calendar.date(byAdding: .hour, value: -2, to: now),
                state: "started",
                progress: 0.72,
                icon: "🎿",
                lead: User(name: "Sarah Chen"),
                targetDate: "2026-05-30"
            ),
            Project(
                id: "proj-2",
                name: "Payments 2.0",
                description: "Reconciliation pipeline overhaul and Stripe webhook hardening.",
                url: "https://linear.app/aigoggles/project/payments-2",
                createdAt: calendar.date(byAdding: .month, value: -2, to: now),
                updatedAt: calendar.date(byAdding: .hour, value: -6, to: now),
                state: "started",
                progress: 0.48,
                icon: "💳",
                lead: User(name: "Sam Okafor"),
                targetDate: "2026-06-15"
            ),
            Project(
                id: "proj-3",
                name: "Audit log",
                description: "Workspace-wide activity log for compliance.",
                url: "https://linear.app/aigoggles/project/audit-log",
                createdAt: calendar.date(byAdding: .month, value: -1, to: now),
                updatedAt: calendar.date(byAdding: .day, value: -1, to: now),
                state: "started",
                progress: 0.22,
                icon: "📘",
                lead: User(name: "Erin Wu"),
                targetDate: "2026-07-01"
            ),
            Project(
                id: "proj-4",
                name: "Strava integration",
                description: "Post-run analytics and ride sharing.",
                url: "https://linear.app/aigoggles/project/strava",
                createdAt: calendar.date(byAdding: .day, value: -18, to: now),
                updatedAt: calendar.date(byAdding: .day, value: -4, to: now),
                state: "planned",
                progress: 0.10,
                icon: "🏔️",
                lead: User(name: "Rafa Patel"),
                targetDate: "2026-08-01"
            )
        ]
    }

    static func getRecentInitiatives() -> [Initiative] {
        let calendar = Calendar.current
        let now = Date()

        return [
            Initiative(
                id: "init-1",
                name: "App Store launch",
                description: "Cross-team push to ship the public release.",
                url: "https://linear.app/aigoggles/initiative/app-store-launch",
                createdAt: calendar.date(byAdding: .month, value: -3, to: now),
                updatedAt: calendar.date(byAdding: .day, value: -2, to: now),
                progress: 0.6,
                icon: "🚀",
                status: "active",
                targetDate: "2026-05-15"
            ),
            Initiative(
                id: "init-2",
                name: "Winter athletes beta",
                description: "Ship the private beta to 100 pro skiers before the next storm cycle.",
                url: "https://linear.app/aigoggles/initiative/beta",
                createdAt: calendar.date(byAdding: .month, value: -1, to: now),
                updatedAt: calendar.date(byAdding: .hour, value: -5, to: now),
                progress: 0.38,
                icon: "🏂",
                status: "active",
                targetDate: "2026-06-10"
            ),
            Initiative(
                id: "init-3",
                name: "Reliability: 99.9% uptime",
                description: "Cycle burndown + alerting + runbooks for every core service.",
                url: "https://linear.app/aigoggles/initiative/reliability",
                createdAt: calendar.date(byAdding: .month, value: -2, to: now),
                updatedAt: calendar.date(byAdding: .day, value: -6, to: now),
                progress: 0.25,
                icon: "🛡️",
                status: "planned",
                targetDate: "2026-09-01"
            )
        ]
    }

    // MARK: - Search

    /// Case-insensitive substring match against `identifier` and `title`.
    /// Empty term returns an empty list so the Search tab stays on its
    /// "start typing" prompt rather than flashing the full issue set.
    static func searchIssues(term: String) -> [Issue] {
        let needle = term.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !needle.isEmpty else { return [] }
        return getRecentIssues().filter {
            $0.identifier.lowercased().contains(needle)
                || $0.title.lowercased().contains(needle)
        }
    }

    static func searchProjects(term: String) -> [Project] {
        let needle = term.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !needle.isEmpty else { return [] }
        return getRecentProjects().filter {
            $0.name.lowercased().contains(needle)
                || ($0.description?.lowercased().contains(needle) ?? false)
        }
    }

    static func searchInitiatives(term: String) -> [Initiative] {
        let needle = term.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !needle.isEmpty else { return [] }
        return getRecentInitiatives().filter {
            $0.name.lowercased().contains(needle)
                || ($0.description?.lowercased().contains(needle) ?? false)
        }
    }

    // MARK: - Notifications

    static func getUnreadNotifications() -> [LinearNotification] {
        let calendar = Calendar.current
        let now = Date()

        return [
            LinearNotification(
                id: "notif-1",
                type: "issueMention",
                createdAt: calendar.date(byAdding: .minute, value: -3, to: now),
                readAt: nil,
                archivedAt: nil,
                snoozedUntilAt: nil,
                actor: NotificationActor(id: "user-1", name: "Marcus Kim", displayName: "Marcus Kim", avatarUrl: nil),
                issue: NotificationIssueTarget(
                    id: "issue-1",
                    identifier: "MLVIS-284",
                    title: "Cursor jumps to top when filtering",
                    url: "https://linear.app/aigoggles/issue/MLVIS-284",
                    state: IssueState(name: "In Progress", type: "started"),
                    priority: 3,
                    priorityLabel: "Medium",
                    team: NotificationTeamRef(id: "team-1", name: "ML Vision", key: "MLVIS"),
                ),
                project: nil,
                document: nil,
            ),
            LinearNotification(
                id: "notif-2",
                type: "issueAssignedToYou",
                createdAt: calendar.date(byAdding: .minute, value: -18, to: now),
                readAt: nil,
                archivedAt: nil,
                snoozedUntilAt: nil,
                actor: NotificationActor(id: "user-2", name: "Jordan Lee", displayName: "Jordan Lee", avatarUrl: nil),
                issue: NotificationIssueTarget(
                    id: "issue-2",
                    identifier: "INFRA-902",
                    title: "Migrate logging pipeline to Vector",
                    url: "https://linear.app/aigoggles/issue/INFRA-902",
                    state: IssueState(name: "Todo", type: "unstarted"),
                    priority: 2,
                    priorityLabel: "High",
                    team: NotificationTeamRef(id: "team-2", name: "Infra", key: "INFRA"),
                ),
                project: nil,
                document: nil,
            ),
            LinearNotification(
                id: "notif-3",
                type: "issueSlaHighRisk",
                createdAt: calendar.date(byAdding: .minute, value: -47, to: now),
                readAt: nil,
                archivedAt: nil,
                snoozedUntilAt: nil,
                actor: NotificationActor(id: "system", name: "Linear", displayName: "Linear", avatarUrl: nil),
                issue: NotificationIssueTarget(
                    id: "issue-3",
                    identifier: "SUP-4419",
                    title: "Stripe webhook retries silently dropped",
                    url: "https://linear.app/aigoggles/issue/SUP-4419",
                    state: IssueState(name: "In Progress", type: "started"),
                    priority: 1,
                    priorityLabel: "Urgent",
                    team: NotificationTeamRef(id: "team-3", name: "Support", key: "SUP"),
                ),
                project: nil,
                document: nil,
            ),
            LinearNotification(
                id: "notif-4",
                type: "issueReviewRequested",
                createdAt: calendar.date(byAdding: .hour, value: -2, to: now),
                readAt: nil,
                archivedAt: nil,
                snoozedUntilAt: nil,
                actor: NotificationActor(id: "user-3", name: "Rafa Patel", displayName: "Rafa Patel", avatarUrl: nil),
                issue: NotificationIssueTarget(
                    id: "issue-4",
                    identifier: "PLAT-221",
                    title: "Cache layer for per-team feature flags",
                    url: "https://linear.app/aigoggles/issue/PLAT-221",
                    state: IssueState(name: "In Review", type: "started"),
                    priority: 3,
                    priorityLabel: "Medium",
                    team: NotificationTeamRef(id: "team-4", name: "Platform", key: "PLAT"),
                ),
                project: nil,
                document: nil,
            ),
            LinearNotification(
                id: "notif-5",
                type: "projectUpdateCreated",
                createdAt: calendar.date(byAdding: .hour, value: -22, to: now),
                readAt: nil,
                archivedAt: nil,
                snoozedUntilAt: nil,
                actor: NotificationActor(id: "user-4", name: "Sam Okafor", displayName: "Sam Okafor", avatarUrl: nil),
                issue: nil,
                project: NotificationProjectTarget(
                    id: "proj-1",
                    name: "Payments 2.0",
                    url: "https://linear.app/aigoggles/project/payments-2",
                    icon: nil,
                    color: "#F2994A"
                ),
                document: nil,
            ),
            LinearNotification(
                id: "notif-6",
                type: "issueNewComment",
                createdAt: calendar.date(byAdding: .day, value: -1, to: now),
                readAt: nil,
                archivedAt: nil,
                snoozedUntilAt: nil,
                actor: NotificationActor(id: "user-5", name: "Erin Wu", displayName: "Erin Wu", avatarUrl: nil),
                issue: NotificationIssueTarget(
                    id: "issue-5",
                    identifier: "DATA-77",
                    title: "Incorrect aggregation in daily active users",
                    url: "https://linear.app/aigoggles/issue/DATA-77",
                    state: IssueState(name: "Todo", type: "unstarted"),
                    priority: 2,
                    priorityLabel: "High",
                    team: NotificationTeamRef(id: "team-5", name: "Data", key: "DATA"),
                ),
                project: nil,
                document: nil,
            )
        ]
    }

    // MARK: - Active cycle (Pulse)

    static func getActiveCycleBundle() -> ActiveCycleBundle {
        let calendar = Calendar.current
        let now = Date()
        let cycleStart = calendar.date(byAdding: .day, value: -9, to: now) ?? now
        let cycleEnd = calendar.date(byAdding: .day, value: 4, to: now) ?? now

        let cycle = LinearCycle(
            id: "cycle-1",
            name: "Platform Cycle 24",
            number: 24,
            startsAt: cycleStart,
            endsAt: cycleEnd,
            progress: 0.67,
            scopeHistory: [44, 46, 48, 50, 52, 53, 53, 54, 55],
            completedScopeHistory: [0, 4, 9, 15, 22, 27, 32, 35, 37],
            inProgressScopeHistory: [2, 3, 4, 4, 5, 5, 4, 5, 5],
            issues: LinearCycle.IssueCollection(nodes: [
                CycleIssue(
                    id: "issue-3",
                    identifier: "SUP-4419",
                    title: "Stripe webhook retries silently dropped",
                    url: "https://linear.app/aigoggles/issue/SUP-4419",
                    updatedAt: calendar.date(byAdding: .hour, value: -1, to: now),
                    dueDate: nil,
                    priority: 1,
                    priorityLabel: "Urgent",
                    state: IssueState(name: "In Progress", type: "started"),
                    assignee: User(name: "Marcus Kim"),
                    slaBreachesAt: calendar.date(byAdding: .minute, value: 47, to: now)
                ),
                CycleIssue(
                    id: "issue-4",
                    identifier: "PLAT-221",
                    title: "Cache layer for per-team feature flags",
                    url: "https://linear.app/aigoggles/issue/PLAT-221",
                    updatedAt: calendar.date(byAdding: .day, value: -3, to: now),
                    dueDate: nil,
                    priority: 3,
                    priorityLabel: "Medium",
                    state: IssueState(name: "In Review", type: "started"),
                    assignee: User(name: "Rafa Patel"),
                    slaBreachesAt: nil
                ),
                CycleIssue(
                    id: "issue-2",
                    identifier: "INFRA-902",
                    title: "Migrate logging pipeline to Vector",
                    url: "https://linear.app/aigoggles/issue/INFRA-902",
                    updatedAt: calendar.date(byAdding: .hour, value: -4, to: now),
                    dueDate: nil,
                    priority: 2,
                    priorityLabel: "High",
                    state: IssueState(name: "Todo", type: "unstarted"),
                    assignee: nil,
                    slaBreachesAt: nil
                ),
                CycleIssue(
                    id: "issue-5",
                    identifier: "DATA-77",
                    title: "Incorrect aggregation in daily active users",
                    url: "https://linear.app/aigoggles/issue/DATA-77",
                    updatedAt: calendar.date(byAdding: .hour, value: -6, to: now),
                    dueDate: nil,
                    priority: 2,
                    priorityLabel: "High",
                    state: IssueState(name: "Blocked", type: "started"),
                    assignee: User(name: "Erin Wu"),
                    slaBreachesAt: nil
                ),
                CycleIssue(
                    id: "issue-6",
                    identifier: "PLAT-240",
                    title: "Audit log retention policy docs",
                    url: "https://linear.app/aigoggles/issue/PLAT-240",
                    updatedAt: calendar.date(byAdding: .day, value: -5, to: now),
                    dueDate: nil,
                    priority: 4,
                    priorityLabel: "Low",
                    state: IssueState(name: "Backlog", type: "backlog"),
                    assignee: User(name: "Sarah Chen"),
                    slaBreachesAt: nil
                )
            ])
        )

        return ActiveCycleBundle(
            teamId: "team-4",
            teamName: "Platform",
            teamKey: "PLAT",
            cycle: cycle
        )
    }

    // MARK: - Pulse

    static func getPulseUpdates() -> [LinearPulseUpdate] {
        let calendar = Calendar.current
        let now = Date()
        func hoursAgo(_ h: Int) -> Date? { calendar.date(byAdding: .hour, value: -h, to: now) }
        func daysAgo(_ d: Int) -> Date? { calendar.date(byAdding: .day, value: -d, to: now) }

        return [
            LinearPulseUpdate(
                id: "upd-1",
                body: """
                Shipped the avalanche-risk detection flag this morning. Field test \
                next week; all four test pairs are passing validation and battery \
                draw is within our 5% budget.
                """,
                createdAt: hoursAgo(2),
                health: "onTrack",
                user: UpdateActor(id: "u-1", name: "Marcus Kim", displayName: "Marcus", avatarUrl: nil),
                project: UpdateProjectRef(
                    id: "project-1",
                    name: "Self-serve onboarding",
                    url: "https://linear.app/aigoggles/project/self-serve-onboarding",
                    color: "#5E6AD2",
                    icon: nil,
                    teams: UpdateProjectTeamsRef(nodes: [UpdateProjectTeamsRef.Node(id: "team-3")])
                ),
                initiative: nil
            ),
            LinearPulseUpdate(
                id: "upd-2",
                body: "Q4 platform initiative now covers 4 of the 6 teams; storage + billing are next.",
                createdAt: hoursAgo(4),
                health: nil,
                user: UpdateActor(id: "u-6", name: "Priya Shah", displayName: "Priya", avatarUrl: nil),
                project: nil,
                initiative: UpdateInitiativeRef(
                    id: "initiative-1",
                    name: "Platform consolidation",
                    url: "https://linear.app/aigoggles/roadmap",
                    color: "#F59E0B",
                    icon: nil
                )
            ),
            LinearPulseUpdate(
                id: "upd-3",
                body: "Migration is two weeks behind after the schema review flagged the refund flow. Reprioritizing the billing-team rotation next sprint to catch up.",
                createdAt: hoursAgo(6),
                health: "atRisk",
                user: UpdateActor(id: "u-2", name: "Elena Rodriguez", displayName: "Elena", avatarUrl: nil),
                project: UpdateProjectRef(
                    id: "project-2",
                    name: "Billing v2 migration",
                    url: "https://linear.app/aigoggles/project/billing-v2",
                    color: "#26B5CE",
                    icon: nil,
                    teams: nil
                ),
                initiative: nil
            ),
            LinearPulseUpdate(
                id: "upd-4",
                body: "AR overlay compositor crashed in cold-start QA. Rolling back to v3.1 on the fleet; cutting a hotfix against the root cause this week.",
                createdAt: daysAgo(1),
                health: "offTrack",
                user: UpdateActor(id: "u-3", name: "Alex Morgan", displayName: "Alex", avatarUrl: nil),
                project: UpdateProjectRef(
                    id: "project-3",
                    name: "AR overlay v4",
                    url: "https://linear.app/aigoggles/project/ar-overlay-v4",
                    color: "#8B5CF6",
                    icon: nil,
                    teams: nil
                ),
                initiative: nil
            ),
            LinearPulseUpdate(
                id: "upd-5",
                body: "Onboarding funnel live on 25% of new activations. Day-1 retention is up 4.2 points versus the old flow.",
                createdAt: daysAgo(2),
                health: "onTrack",
                user: UpdateActor(id: "u-4", name: "Rafa Patel", displayName: "Rafa", avatarUrl: nil),
                project: UpdateProjectRef(
                    id: "project-1",
                    name: "Self-serve onboarding",
                    url: "https://linear.app/aigoggles/project/self-serve-onboarding",
                    color: "#5E6AD2",
                    icon: nil,
                    teams: UpdateProjectTeamsRef(nodes: [UpdateProjectTeamsRef.Node(id: "team-3")])
                ),
                initiative: nil
            ),
            LinearPulseUpdate(
                id: "upd-6",
                body: "Growth leadership review: trimming the scope to the three bets with clearest signal. Detailed write-up in the linked doc.",
                createdAt: daysAgo(3),
                health: nil,
                user: UpdateActor(id: "u-7", name: "Sarah Chen", displayName: "Sarah", avatarUrl: nil),
                project: nil,
                initiative: UpdateInitiativeRef(
                    id: "initiative-2",
                    name: "Growth experiments Q4",
                    url: "https://linear.app/aigoggles/roadmap",
                    color: "#10B981",
                    icon: nil
                )
            )
        ]
    }

    // MARK: - Favorites

    static func getFavorites() -> [LinearFavorite] {
        [
            LinearFavorite(
                id: "fav-1",
                type: "issue",
                folderName: "Daily",
                issue: FavoriteIssueTarget(
                    id: "issue-3",
                    identifier: "SUP-4419",
                    title: "Stripe webhook retries silently dropped",
                    url: "https://linear.app/aigoggles/issue/SUP-4419",
                    state: IssueState(name: "In Progress", type: "started"),
                    team: Team(id: "team-3", name: "Support", key: "SUP", icon: nil)
                ),
                project: nil,
                customView: nil
            ),
            LinearFavorite(
                id: "fav-2",
                type: "project",
                folderName: "Daily",
                issue: nil,
                project: FavoriteProjectTarget(
                    id: "project-1",
                    name: "Self-serve onboarding",
                    url: "https://linear.app/aigoggles/project/self-serve-onboarding",
                    icon: nil,
                    color: "#5E6AD2",
                    state: "started",
                    progress: 0.42
                ),
                customView: nil
            ),
            LinearFavorite(
                id: "fav-3",
                type: "customView",
                folderName: nil,
                issue: nil,
                project: nil,
                customView: FavoriteCustomViewTarget(
                    id: "view-1",
                    name: "High priority bugs",
                    icon: nil,
                    color: "#EF4444"
                )
            ),
            LinearFavorite(
                id: "fav-4",
                type: "issue",
                folderName: nil,
                issue: FavoriteIssueTarget(
                    id: "issue-5",
                    identifier: "DEBR-265",
                    title: "Notion Database for /go pages",
                    url: "https://linear.app/aigoggles/issue/DEBR-265",
                    state: IssueState(name: "In Progress", type: "started"),
                    team: Team(id: "team-5", name: "Developer Relations", key: "DEBR", icon: nil)
                ),
                project: nil,
                customView: nil
            ),
            LinearFavorite(
                id: "fav-5",
                type: "project",
                folderName: nil,
                issue: nil,
                project: FavoriteProjectTarget(
                    id: "project-2",
                    name: "Billing v2 migration",
                    url: "https://linear.app/aigoggles/project/billing-v2",
                    icon: nil,
                    color: "#26B5CE",
                    state: "planned",
                    progress: 0.05
                ),
                customView: nil
            )
        ]
    }

}
