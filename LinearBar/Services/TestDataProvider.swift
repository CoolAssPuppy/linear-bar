import Foundation

#if DEBUG
/// Provides test data for UI testing screenshots
/// Fictional AI Ski Goggles company with funny but professional content
struct TestDataProvider {

    static var isUITesting: Bool {
        CommandLine.arguments.contains("--uitesting")
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

    // MARK: - Favorites

    static func getFavorites() -> [Favorite] {
        let calendar = Calendar.current
        let now = Date()

        return [
            // Favorite Issue: Snowflake Detection Bug
            Favorite(
                id: "fav-1",
                type: "issue",
                sortOrder: 1.0,
                folderName: nil,
                issue: Issue(
                    id: "issue-1",
                    identifier: "AG-247",
                    title: "Fix snowflake detection AI hallucinating penguins",
                    url: "https://linear.app/aigoggles/issue/AG-247",
                    createdAt: calendar.date(byAdding: .day, value: -5, to: now),
                    updatedAt: calendar.date(byAdding: .hour, value: -2, to: now),
                    dueDate: "2025-11-10",
                    state: IssueState(name: "In Progress", type: "started"),
                    priority: 1,
                    priorityLabel: "Urgent",
                    assignee: User(name: "Marcus Kim"),
                    team: Team(id: "team-1", name: "ML Vision", key: "MLVIS", icon: "🤖"),
                    labels: LabelConnection(nodes: [
                        IssueLabel(id: "label-1", name: "bug", color: "#EF4444"),
                        IssueLabel(id: "label-2", name: "ai-model", color: "#8B5CF6")
                    ]),
                    project: ProjectReference(id: "proj-1", name: "Winter 2025 Launch", icon: "🎿"),
                    parent: nil
                ),
                project: nil,
                initiative: nil,
                customView: nil,
                cycle: nil,
                label: nil,
                parent: nil,
                children: nil
            ),

            // Favorite Issue: Battery Performance
            Favorite(
                id: "fav-2",
                type: "issue",
                sortOrder: 2.0,
                folderName: nil,
                issue: Issue(
                    id: "issue-2",
                    identifier: "AG-189",
                    title: "Battery drains faster in cold weather (obviously)",
                    url: "https://linear.app/aigoggles/issue/AG-189",
                    createdAt: calendar.date(byAdding: .day, value: -12, to: now),
                    updatedAt: calendar.date(byAdding: .day, value: -1, to: now),
                    dueDate: "2025-11-15",
                    state: IssueState(name: "Todo", type: "unstarted"),
                    priority: 2,
                    priorityLabel: "High",
                    assignee: User(name: "Elena Rodriguez"),
                    team: Team(id: "team-2", name: "Hardware", key: "HW", icon: "⚡"),
                    labels: LabelConnection(nodes: [
                        IssueLabel(id: "label-3", name: "hardware", color: "#F59E0B"),
                        IssueLabel(id: "label-4", name: "power", color: "#10B981")
                    ]),
                    project: ProjectReference(id: "proj-1", name: "Winter 2025 Launch", icon: "🎿"),
                    parent: nil
                ),
                project: nil,
                initiative: nil,
                customView: nil,
                cycle: nil,
                label: nil,
                parent: nil,
                children: nil
            ),

            // Favorite Project
            Favorite(
                id: "fav-3",
                type: "project",
                sortOrder: 3.0,
                folderName: nil,
                issue: nil,
                project: Project(
                    id: "proj-1",
                    name: "Winter 2025 Launch",
                    url: "https://linear.app/aigoggles/project/winter-2025",
                    createdAt: calendar.date(byAdding: .month, value: -3, to: now),
                    updatedAt: calendar.date(byAdding: .hour, value: -6, to: now),
                    state: "started",
                    progress: 0.67,
                    icon: "🎿",
                    lead: User(name: "Sarah Chen"),
                    targetDate: "2025-12-01"
                ),
                initiative: nil,
                customView: nil,
                cycle: nil,
                label: nil,
                parent: nil,
                children: nil
            ),

            // Favorite: Custom View
            Favorite(
                id: "fav-4",
                type: "customView",
                sortOrder: 4.0,
                folderName: nil,
                issue: nil,
                project: nil,
                initiative: nil,
                customView: FavoriteItem(
                    id: "view-1",
                    name: "My Issues This Sprint",
                    icon: "🏂",
                    url: "https://linear.app/aigoggles/view/my-sprint",
                    color: "#5E6AD2",
                    startsAt: nil,
                    endsAt: nil
                ),
                cycle: nil,
                label: nil,
                parent: nil,
                children: nil
            )
        ]
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

    static func getProjects() -> [Project] {
        let calendar = Calendar.current
        let now = Date()

        return [
            Project(
                id: "proj-1",
                name: "Winter 2025 Launch",
                url: "https://linear.app/aigoggles/project/winter-2025",
                createdAt: calendar.date(byAdding: .month, value: -3, to: now),
                updatedAt: calendar.date(byAdding: .hour, value: -6, to: now),
                state: "started",
                progress: 0.67,
                icon: "🎿",
                lead: User(name: "Sarah Chen"),
                targetDate: "2025-12-01"
            ),
            Project(
                id: "proj-2",
                name: "Mobile App 2.0",
                url: "https://linear.app/aigoggles/project/mobile-2",
                createdAt: calendar.date(byAdding: .month, value: -2, to: now),
                updatedAt: calendar.date(byAdding: .day, value: -1, to: now),
                state: "started",
                progress: 0.45,
                icon: "📱",
                lead: User(name: "Jordan Lee"),
                targetDate: "2026-01-15"
            ),
            Project(
                id: "proj-3",
                name: "Summer Product Research",
                url: "https://linear.app/aigoggles/project/summer-research",
                createdAt: calendar.date(byAdding: .weekOfYear, value: -2, to: now),
                updatedAt: calendar.date(byAdding: .day, value: -3, to: now),
                state: "planned",
                progress: 0.12,
                icon: "🔬",
                lead: User(name: "Elena Rodriguez"),
                targetDate: "2026-04-01"
            )
        ]
    }

    // MARK: - Initiatives

    static func getInitiatives() -> [Initiative] {
        let calendar = Calendar.current
        let now = Date()

        return [
            Initiative(
                id: "init-1",
                name: "Become #1 AI Ski Goggle Company (there are dozens of us!)",
                url: "https://linear.app/aigoggles/initiative/market-leader",
                createdAt: calendar.date(byAdding: .month, value: -6, to: now),
                updatedAt: calendar.date(byAdding: .weekOfYear, value: -1, to: now),
                progress: 0.58,
                icon: "🏆",
                status: "active",
                targetDate: "2025-12-31"
            ),
            Initiative(
                id: "init-2",
                name: "Expand to Snowboarding (controversial internally)",
                url: "https://linear.app/aigoggles/initiative/snowboarding",
                createdAt: calendar.date(byAdding: .month, value: -4, to: now),
                updatedAt: calendar.date(byAdding: .day, value: -5, to: now),
                progress: 0.23,
                icon: "🏂",
                status: "planned",
                targetDate: "2026-06-01"
            )
        ]
    }
}
#endif
