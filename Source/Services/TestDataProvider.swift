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
                urlKey: "aigoggles"
            )
        )
    }


    // MARK: - Recent Issues

    static func getRecentIssues() -> [Issue] {
        let calendar = Calendar.current
        let now = Date()

        return [
            Issue(
                id: "issue-3",
                identifier: "AG-301",
                title: "Implement \"Are those clouds or avalanche risk?\" detection",
                description: nil,
                url: "https://linear.app/aigoggles/issue/AG-301",
                createdAt: calendar.date(byAdding: .hour, value: -3, to: now),
                updatedAt: calendar.date(byAdding: .minute, value: -15, to: now),
                dueDate: nil,
                state: IssueState(name: "In Progress", type: "started"),
                priority: 2,
                priorityLabel: "High",
                assignee: User(name: "Marcus Kim"),
                team: Team(id: "team-1", name: "ML Vision", key: "MLVIS", icon: "🤖"),
                labels: LabelConnection(nodes: [
                    IssueLabel(id: "label-5", name: "feature", color: "#3B82F6"),
                    IssueLabel(id: "label-6", name: "safety", color: "#EF4444")
                ]),
                project: ProjectReference(id: "proj-1", name: "Winter 2025 Launch", icon: "🎿"),
                parent: nil
            ),
            Issue(
                id: "issue-4",
                identifier: "AG-298",
                title: "Add \"friend detection\" to stop yelling at strangers",
                description: nil,
                url: "https://linear.app/aigoggles/issue/AG-298",
                createdAt: calendar.date(byAdding: .hour, value: -8, to: now),
                updatedAt: calendar.date(byAdding: .hour, value: -1, to: now),
                dueDate: "2025-11-12",
                state: IssueState(name: "In Review", type: "started"),
                priority: 3,
                priorityLabel: "Medium",
                assignee: User(name: "Jordan Lee"),
                team: Team(id: "team-1", name: "ML Vision", key: "MLVIS", icon: "🤖"),
                labels: LabelConnection(nodes: [
                    IssueLabel(id: "label-7", name: "social", color: "#EC4899"),
                    IssueLabel(id: "label-8", name: "ml-training", color: "#8B5CF6")
                ]),
                project: nil,
                parent: nil
            ),
            Issue(
                id: "issue-5",
                identifier: "AG-287",
                title: "Goggles fog up when user is too excited about powder",
                description: nil,
                url: "https://linear.app/aigoggles/issue/AG-287",
                createdAt: calendar.date(byAdding: .day, value: -1, to: now),
                updatedAt: calendar.date(byAdding: .hour, value: -4, to: now),
                dueDate: "2025-11-20",
                state: IssueState(name: "Todo", type: "unstarted"),
                priority: 2,
                priorityLabel: "High",
                assignee: User(name: "Elena Rodriguez"),
                team: Team(id: "team-2", name: "Hardware", key: "HW", icon: "⚡"),
                labels: LabelConnection(nodes: [
                    IssueLabel(id: "label-9", name: "hardware", color: "#F59E0B"),
                    IssueLabel(id: "label-10", name: "ux", color: "#06B6D4")
                ]),
                project: ProjectReference(id: "proj-1", name: "Winter 2025 Launch", icon: "🎿"),
                parent: nil
            ),
            Issue(
                id: "issue-6",
                identifier: "AG-275",
                title: "Document: \"How to explain to investors why we need AI for skiing\"",
                description: nil,
                url: "https://linear.app/aigoggles/issue/AG-275",
                createdAt: calendar.date(byAdding: .day, value: -2, to: now),
                updatedAt: calendar.date(byAdding: .hour, value: -18, to: now),
                dueDate: nil,
                state: IssueState(name: "Done", type: "completed"),
                priority: 4,
                priorityLabel: "Low",
                assignee: User(name: "Sarah Chen"),
                team: Team(id: "team-3", name: "Product", key: "PROD", icon: "📱"),
                labels: LabelConnection(nodes: [
                    IssueLabel(id: "label-11", name: "documentation", color: "#6B7280")
                ]),
                project: nil,
                parent: nil
            ),
            Issue(
                id: "issue-7",
                identifier: "AG-264",
                title: "AR overlay shows \"You're doing great!\" even during faceplant",
                description: nil,
                url: "https://linear.app/aigoggles/issue/AG-264",
                createdAt: calendar.date(byAdding: .day, value: -3, to: now),
                updatedAt: calendar.date(byAdding: .day, value: -1, to: now),
                dueDate: "2025-11-08",
                state: IssueState(name: "In Progress", type: "started"),
                priority: 1,
                priorityLabel: "Urgent",
                assignee: User(name: "Alex Morgan"),
                team: Team(id: "team-4", name: "AR Experience", key: "AR", icon: "🥽"),
                labels: LabelConnection(nodes: [
                    IssueLabel(id: "label-12", name: "bug", color: "#EF4444"),
                    IssueLabel(id: "label-13", name: "ar-display", color: "#8B5CF6")
                ]),
                project: ProjectReference(id: "proj-1", name: "Winter 2025 Launch", icon: "🎿"),
                parent: nil
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
                name: "Payments 2.0",
                description: "Reconciliation pipeline overhaul.",
                url: "https://linear.app/aigoggles/project/payments-2",
                createdAt: calendar.date(byAdding: .month, value: -2, to: now),
                updatedAt: calendar.date(byAdding: .hour, value: -6, to: now),
                state: "started",
                progress: 0.48,
                icon: "💳",
                lead: User(name: "Sam Okafor"),
                targetDate: "2026-05-30"
            ),
            Project(
                id: "proj-2",
                name: "Audit log",
                description: nil,
                url: "https://linear.app/aigoggles/project/audit-log",
                createdAt: calendar.date(byAdding: .month, value: -1, to: now),
                updatedAt: calendar.date(byAdding: .day, value: -1, to: now),
                state: "started",
                progress: 0.22,
                icon: "📘",
                lead: User(name: "Erin Wu"),
                targetDate: "2026-06-15"
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
            )
        ]
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

}
