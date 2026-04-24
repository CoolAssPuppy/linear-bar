# Linear API capabilities for Linear Bar

A reference and design document for what we can build in a menu bar app, grounded in what the Linear GraphQL API actually exposes. Every field, query, and feature here is checked against the canonical schema at `linear/linear` on GitHub. When the developer docs and the schema disagree, the schema wins.

Endpoint: `https://api.linear.app/graphql`. GraphQL only. No REST.

## How to read this doc

- Part A: Conventions every query inherits.
- Part B: Core objects and the fields worth caring about.
- Part C: The "what have I touched?" question. Activity, history, notifications.
- Part D: Metrics that fit in a popover. What's pre-computed vs. client-side.
- Part E: Auth, rate limits, gotchas worth knowing before you write a query.
- Part F: Feature catalog ranked by glance quality.
- Part G: Top five recommendations if we only shipped five widgets.
- Part H: Open questions for discussion.

## Part A: Conventions every query inherits

These apply to almost every plural connection in the schema. Memorize them once and you stop rediscovering them.

**Pagination.** Relay-style cursors. Arguments: `first`, `last`, `after`, `before`. Default page size is 50. Response shape is either `nodes { ... }` (preferred) or `edges { node, cursor }`, plus `pageInfo { hasNextPage, endCursor }`. For us, always use `nodes` unless we need per-edge metadata.

**Ordering.** `orderBy: PaginationOrderBy` accepts exactly two values: `createdAt` (default) and `updatedAt`. There is no server-side sort by priority, due date, or estimate. Those are client-side. Plan for it.

**Archives.** Every connection takes `includeArchived: Boolean`. Default is `false`. If we're doing historical reporting (velocity across six cycles, for example), we probably want to flip it on.

**Dates.** Filter inputs like `updatedAt` and `dueDate` take a `DateTimeOrDuration` scalar. That means you can pass an absolute timestamp (`"2026-04-23T00:00:00Z"`) or a relative ISO 8601 duration (`"P1W"` = one week ago, `"P1D"` = yesterday, `"P2H"` = two hours ago). Durations are resolved server-side at request time. Use them, because the server caches them.

**Comparators.** Scalar filters accept `{ eq, neq, lt, lte, gt, gte, in, nin, null }`. String filters add `contains`, `containsIgnoreCase`, `startsWith`, `endsWith`, `eqIgnoreCase`. Collection filters accept `some`, `every`, `and`, `or`.

**Rate limit headers.** Every response includes `X-RateLimit-Requests-Remaining`, `X-RateLimit-Complexity-Remaining`, `X-Complexity` (this request's cost), and `Reset` values as UTC epoch ms. Tail these in dev.

## Part B: Core objects

Every first-class type below has `id`, `createdAt`, `updatedAt`, and `archivedAt`. I'll skip those in each section.

### Issue

The main object. It's also the one with the richest filter input in the whole API.

**Scalar and timestamp fields worth knowing:**

- Identity: `title`, `identifier` (`ENG-123`), `number`, `branchName`, `url`, `description`, `previousIdentifiers`.
- Prioritization: `priority` (0=none, 1=urgent, 2=high, 3=medium, 4=low), `priorityLabel`, `estimate`, `dueDate`, `sortOrder`, `subIssueSortOrder`.
- Lifecycle timestamps: `createdAt`, `updatedAt`, `startedAt`, `completedAt`, `canceledAt`, `autoArchivedAt`, `autoClosedAt`, `triagedAt`, `startedTriageAt`, `snoozedUntilAt`, `addedToCycleAt`, `addedToProjectAt`, `addedToTeamAt`.
- SLA: `slaStartedAt`, `slaBreachesAt`, `slaHighRiskAt`, `slaMediumRiskAt`, `slaType`.
- Customer signal: `customerTicketCount` (integer count of linked customer tickets).
- Reactions: `reactionData` (JSON).

**Relations:**

- People: `assignee`, `creator`, `delegate`, `snoozedBy`, `subscribers`, `botActor`.
- Hierarchy: `parent`, `children`, `team`, `state`, `cycle`, `project`, `projectMilestone`, `labels`, `labelIds`.
- Discussion: `comments`, `attachments`, `reactions`, `needs` (customer needs).
- History: `history` (per-change log), `stateHistory` (pre-aggregated time in state).
- Relations: `relations`, `inverseRelations`, `sourceComment` (the comment an issue was spun out of), `lastAppliedTemplate`.
- External sync: `syncedWith` (GitHub PR, Slack thread, etc.).

**Derived durations on the filter input, not readable as fields.** These exist on `IssueFilter` / `IssueCollectionFilter`:

- `cycleTime: NullableDurationComparator`. Started to completed.
- `leadTime: NullableDurationComparator`. Created to completed.
- `triageTime: NullableDurationComparator`. Created to triaged.
- `ageTime: NullableDurationComparator`. Created to now, for open issues.

So you can filter for "issues that took more than a week to complete" without replaying history: `issues(filter: { cycleTime: { gt: "P1W" } })`.

**IssueStateSpan.** `Issue.stateHistory` is its own connection that returns `IssueStateSpan { state, startedAt, endedAt }`. This is the cheap way to measure how long an issue sat in "In Review" or "Blocked". Use this instead of `IssueHistory`.

**Other filter goodies:** `hasBlockedByRelations`, `hasBlockingRelations`, `hasDuplicateRelations`, `hasRelatedRelations`, `hasSharedUsers`, `slaStatus`. Nested filters chain across relations with the usual `some` / `every` / `and` / `or`.

### Project

**Fields:**

- Identity: `name`, `description`, `content` (full markdown body), `slugId`, `url`, `color`, `icon`, `priority`, `priorityLabel`, `sortOrder`.
- Status: `status: ProjectStatus!` (has a sub-type: `backlog`, `planned`, `started`, `paused`, `completed`, `canceled`). `state: String!` is deprecated — use `status`.
- Health: `health: ProjectUpdateHealthType` (`onTrack`, `atRisk`, `offTrack`), `healthUpdatedAt`, `lastUpdate: ProjectUpdate` (the freshest update, with its own `isStale: Boolean!` flag).
- Dates: `startDate`, `targetDate`, `startDateResolution`, `targetDateResolution` (month / quarter / half / year), `startedAt`, `completedAt`, `canceledAt`, `autoArchivedAt`.

**The pre-computed rollups.** These are per-week arrays, index-aligned, that you can plot without any aggregation work:

- `issueCountHistory: [Float!]!`
- `completedIssueCountHistory: [Float!]!`
- `scopeHistory: [Float!]!`
- `completedScopeHistory: [Float!]!`
- `inProgressScopeHistory: [Float!]!`
- `progress: Float!`
- `progressHistory: JSONObject!`
- `currentProgress: JSONObject!`

**Relations.** `creator`, `lead`, `members`, `teams`, `initiatives`, `projectMilestones`, `projectUpdates`, `documents`, `issues`, `labels`, `needs`, `attachments`, `externalLinks`, `comments`, `history`, `relations`.

### Cycle

**Fields:** `name`, `number`, `description`, `startsAt`, `endsAt`, `completedAt`, `autoArchivedAt`, `progress`, `isActive`, `isFuture`, `isNext`, `isPast`, `isPrevious`.

**Burndown is served pre-computed.** Same per-day parallel arrays as Project, aligned against `startsAt..endsAt`:

- `issueCountHistory`, `completedIssueCountHistory`, `scopeHistory`, `completedScopeHistory`, `inProgressScopeHistory`.
- `progressHistory` (JSON), `currentProgress` (JSON).

**Relations.** `team`, `issues`, `uncompletedIssuesUponClose` (the slip-over list — great for a retro widget).

**Filter goodies.** `isActive`, `isNext`, `isPast`, `isPrevious`, `isInCooldown`. Combine with `Team.activeCycle` for "what's my team on right now."

### Initiative

Replaces the deprecated `Roadmap`. Tree-shaped: initiatives can have parent initiatives, and join to projects through `InitiativeToProject` edges with their own sort order.

**Fields:** `name`, `description`, `content`, `icon`, `color`, `completedAt`, `health: InitiativeUpdateHealthType` (same tri-state as Project), `healthUpdatedAt`, `lastUpdate: InitiativeUpdate`.

**Relations:** `owner`, `creator`, `parentInitiative`, `parentInitiatives`, `projects`, `initiativeUpdates`, `documents`, `links`, `history`.

### ProjectMilestone

Smaller object but useful for "upcoming dates" widgets.

**Fields:** `name`, `description`, `targetDate`, `status: ProjectMilestoneStatus`, `sortOrder`, `progress`, `progressHistory`, `currentProgress`, `project`, `issues`.

### Team

Big type. The fields that matter for us:

- Identity: `name`, `key`, `color`, `icon`, `description`, `private`, `timezone`.
- Cycle config: `cycleDuration`, `cycleCooldownTime`, `cycleStartDay`, `cyclesEnabled`, `cycleCalenderUrl` (iCal).
- Auto-close and archive policy: `autoArchivePeriod`, `autoClosePeriod`.
- Active state: `activeCycle` (convenience accessor, saves a filter query), `defaultIssueState`, `triageIssueState`, `draftWorkflowState`.
- Hierarchy: `parent`, `children`, `ancestors`.
- Relations: `cycles`, `issues`, `projects`, `members`, `memberships`, `labels`, `states`, `organization`.

### User and `viewer`

`viewer: User!` is the identity query. Returns the currently authenticated user.

**Fields on User:** `name`, `displayName`, `email`, `avatarUrl`, `initials`, `active`, `admin`, `owner`, `guest`, `app`, `isMe`, `isAssignable`, `isMentionable`, `timezone`, `title`, `lastSeen`, `statusEmoji`, `statusLabel`, `statusUntilAt`, `url`, `createdIssueCount`.

**`isMe: Boolean!`** is nestable inside any user filter. This is the magic that makes "my issues" queries clean without round-tripping to get the viewer id.

**Per-user connections:** `assignedIssues`, `createdIssues`, `delegatedIssues`, `teams`, `teamMemberships`, `drafts`, `issueDrafts`.

### Comment

`body` (markdown), `bodyData` (ProseMirror JSON), `user`, `externalUser`, `parent`, `children`, `issue`, `project`, `projectUpdate`, `initiative`, `initiativeUpdate`, `documentContent`, `resolvedAt`, `resolvingUser`, `resolvingComment`, `reactionData`, `reactions`, `quotedText`, `externalThread`, `syncedWith`, `threadSummary` (JSON, AI-generated but internal), `url`.

### Attachment

`title`, `subtitle`, `url`, `metadata` (JSON), `source` (JSON), `sourceType` (`"github"`, `"slack"`, `"zendesk"`, etc.), `groupBySource`, `creator`, `externalUserCreator`, `issue`, `originalIssue`. Filterable by `sourceType` — handy for a "GitHub PR activity" row.

### WorkflowState

`name`, `color`, `description`, `position`, `type`, `team`, `issues`, `inheritedFrom`.

**`type` is critical.** It's one of `"triage" | "backlog" | "unstarted" | "started" | "completed" | "canceled" | "duplicate"`. This is how you classify states cross-team. Do not filter by state name (`"In Progress"`); filter by `state.type`. Teams pick their own state names.

### IssueLabel

`name`, `description`, `color`, `isGroup`, `parent`, `children` (labels form groups), `creator`, `team` (null means workspace-wide), `issues`.

### Document

`title`, `content` (markdown), `icon`, `color`, `slugId`, `url`, `creator`, `updatedBy`, `hiddenAt`. Parent can be any of `project`, `initiative`, `issue`, `cycle`, `release`.

### CustomerNeed

The customer-facing signal layer. `body`, `priority` (0 / 1), `customer: Customer`, `issue`, `project`, `attachment`, `projectAttachment`, `comment`, `creator`, `url`. Use these to surface "X customers asked for this."

### ProjectUpdate and InitiativeUpdate

`body` (markdown), `bodyData`, `diff` (JSON), `diffMarkdown`, `health: ProjectUpdateHealthType!` (required on each update), `isStale: Boolean!`, `editedAt`, `project`, `user`, `commentCount`, `comments`, `reactions`, `reactionData`, `infoSnapshot` (JSON: team / milestone / issue stats at the moment of the write, useful for retroactive metric cards), `url`.

### IssueHistory

Every field change is recorded with `from<X>` / `to<X>` pairs. Full list of tracked fields: `fromStateId` / `toStateId`, `fromAssigneeId` / `toAssigneeId`, `fromCycleId` / `toCycleId`, `fromProjectId` / `toProjectId`, `fromProjectMilestone` / `toProjectMilestone`, `fromParentId` / `toParentId`, `fromTeamId` / `toTeamId`, `fromPriority` / `toPriority`, `fromEstimate` / `toEstimate`, `fromDueDate` / `toDueDate`, `fromTitle` / `toTitle`, `fromSlaBreachesAt` / `toSlaBreachesAt`, `fromSlaType` / `toSlaType`, `fromSlaStartedAt` / `toSlaStartedAt`, `fromSlaBreached` / `toSlaBreached`, `fromDelegate` / `toDelegate`, `addedLabelIds` / `addedLabels`, `removedLabelIds` / `removedLabels`, `addedToReleaseIds` / `removedFromReleaseIds`, `relationChanges`, `archived`, `autoArchived`, `autoClosed`, `trashed`, `updatedDescription`, `actor`, `botActor`.

**Important.** There is no root `IssueHistoryFilter`. You can only page history through an issue's `history(...)` connection. So "what did the team do yesterday?" is a per-issue question, not a workspace-wide query.

## Part C: The "what have I touched?" question

Three surfaces give you activity, and they're not interchangeable.

### Surface 1: The `issues` query with `isMe` filters

For a Recent tab in the spirit of "anything I'm on," this is the cleanest single call:

```graphql
query Recent($since: DateTimeOrDuration!) {
  viewer { id }
  issues(
    first: 50
    orderBy: updatedAt
    filter: {
      updatedAt: { gt: $since }
      or: [
        { assignee: { isMe: { eq: true } } }
        { creator: { isMe: { eq: true } } }
        { subscribers: { some: { isMe: { eq: true } } } }
        { comments: { some: { user: { isMe: { eq: true } } } } }
      ]
    }
  ) {
    nodes {
      id
      identifier
      title
      url
      priority
      updatedAt
      state { name type color }
      assignee { displayName avatarUrl }
      team { key name }
      project { id name }
    }
    pageInfo { hasNextPage endCursor }
  }
}
```

Pass `"P1W"` for `$since` and the server resolves it for you. This covers your "Recent tab" request directly. Linear auto-subscribes the assignee, creator, and anyone who comments, so in practice the four clauses above capture almost everything you'd call "touched."

### Surface 2: The `notifications` query

This is the real inbox. It's the same data feeding Linear's own notification bell, already deduped and grouped.

```graphql
query Inbox {
  notifications(first: 50, filter: { readAt: { null: true } }) {
    nodes {
      id
      type
      category
      createdAt
      readAt
      snoozedUntilAt
      url
      title
      subtitle
      actor { displayName avatarUrl }
      ... on IssueNotification { issue { identifier title url } commentId reactionEmoji }
      ... on ProjectNotification { project { id name url } }
      ... on DocumentNotification { document { id title url } }
    }
  }
  notificationsUnreadCount
}
```

`NotificationCategory` enumerates what shows up: `assignments`, `mentions`, `commentsAndReplies`, `reactions`, `statusChanges`, `reviews`, `postsAndUpdates` (project / initiative updates), `documentChanges`, `triage`, `reminders`, `subscriptions`, `customers`, `appsAndIntegrations`, `feed`, `system`.

### Surface 3: Per-issue `history` connection

Only useful when you're already on an issue. Not useful for a workspace-wide feed.

### Which to use for Linear Bar

- **"Recent" tab** = surface 1. Answers "what issues have I been near recently."
- **"Inbox" tab** (new) = surface 2. Answers "what does Linear think I should look at." This is probably more valuable than Recent for day-to-day use.
- **Menu bar badge** = `notificationsUnreadCount` (one integer, trivial cost).

I'd recommend adding Inbox as a primary tab and keeping Recent as a secondary view.

## Part D: Metrics that fit in a popover

Menu bar reality: ~360px wide, variable height, readable at a glance. That rules out most dashboards. But a surprising number of leader-level metrics reduce to single rows or sparklines.

### Pre-computed, zero aggregation

These are the cheap wins. Linear already runs the math; we just plot or render.

| Metric | Field |
| --- | --- |
| Cycle burndown | `Cycle.scopeHistory` vs. `completedScopeHistory`, plotted over `startsAt..endsAt` |
| Cycle velocity | `Team.cycles(last: 6).completedScopeHistory` final values, then take a trailing average |
| Project progress | `Project.progress` (single float) |
| Project weekly scope history | `Project.scopeHistory` |
| Project health color | `Project.health` (direct `onTrack` / `atRisk` / `offTrack`) |
| Stale project flag | `Project.lastUpdate.isStale` |
| Active cycle per team | `Team.activeCycle` (saves a filter query) |
| Unread count for menu bar badge | `notificationsUnreadCount` |
| Issue cycle/lead/triage time filter | `IssueFilter.cycleTime` / `leadTime` / `triageTime` comparators |
| Per-state time in an issue | `Issue.stateHistory[].{startedAt, endedAt}` |
| SLA risk/breach | `Issue.slaBreachesAt`, `slaHighRiskAt`, `slaMediumRiskAt`, `slaStatus` filter |
| Initiative rollup | `Initiative.projects` with health and progress on each |
| Rate limit budget | `rateLimitStatus` |

### Client-side aggregation required

These need us to fetch and fold.

| Metric | How |
| --- | --- |
| Issue count by state per team | Fetch team issues, bucket by `state.id`. No server-side `count`. |
| Workload balance across team | `team.members { assignedIssues(filter: { state: { type: { in: ["started", "unstarted"] } } }) { estimate } }`, sum `estimate` per assignee. |
| Label / priority distribution | Fetch filtered issues, tally. |
| Reviewer load, triage backlog | Same pattern: filter then count. |
| Cycle time histogram | `issues(filter: { completedAt: { gt: "P4W" }, cycleTime: { null: false } })`, then bin `(completedAt - startedAt)` client-side. |
| Velocity forecast | Regress over the last six `completedScopeHistory` endpoints. |
| Scope creep per project | Diff `scopeHistory[last]` vs. `scopeHistory[first]`. |
| Recently churned issues | Walk `Issue.history` looking for repeated state transitions in a window. Expensive; do it only on demand. |

### The cost calculus

A query returning 50 issues with ~15 scalar fields each costs about 100 complexity points. The budget for OAuth is 2,000,000 points per hour. That's a ceiling of ~20,000 full-page queries per hour if we did nothing else. We won't get close. But a dashboard that naively pulls every team's full issue list every 30 seconds will grind through it fast.

The pattern that stays cheap:

1. On startup, fetch the baseline: `viewer`, `teams`, `projects` with health only.
2. On every refresh tick (30-60s), poll only deltas: `issues(filter: { updatedAt: { gt: "PT1M" } })` and `notifications`.
3. On a slower tick (5-10 min), refresh cycle / project rollups.

## Part E: Auth, rate limits, gotchas

### OAuth vs. Personal API Key

**Personal API Key.** Single header `Authorization: <key>` (no `Bearer` prefix). Scoped to whoever created it. 5,000 requests and 3,000,000 complexity points per hour. Simple, but it inherits the user's admin scope and requires each user to generate a key in their Linear settings.

**OAuth 2.0 with PKCE.** `Authorization: Bearer <token>`. Scopes: `read` (always), `write`, `issues:create`, `comments:create`, `timeSchedule:write`, `admin`. Access tokens live 24h. Refresh tokens have a 30-minute replay grace for network retries. 5,000 requests and 2,000,000 complexity points per hour. PKCE makes `client_secret` optional, which is exactly what a distributed desktop app needs.

**Recommendation for Linear Bar.** Ship OAuth with PKCE, scopes `read` by default and `issues:create` + `comments:create` if we want quick-actions. Drop the personal API key path entirely.

**Redirect URIs for desktop.** Linear's docs show HTTP examples (`http://localhost:3000/oauth/callback`). Custom URL schemes (`linearbar://callback`) aren't explicitly confirmed but are what the current app uses successfully. The fallback pattern is an ephemeral `localhost` HTTP listener during the auth flow, matching the GitHub CLI / Google native-app approach.

### Rate limit details

Complexity is weighted. Each scalar = 0.1 point, each object = 1 point, each connection multiplies children by page size. Example: 50 issues, each with 15 scalars + 1 object relation = 50 × (0.1 × 15 + 1) + 1 ≈ 126 points. A single query cannot exceed 10,000 points.

Exceeding the hourly budget returns HTTP 400 with `extensions.code = "RATELIMITED"`. The response still contains partial data sometimes, so check `errors` even on 200s.

### Real-time: subscriptions vs. webhooks vs. polling

**Subscriptions.** The schema defines a `type Subscription` with 71 events. Linear does not publicly document a WebSocket endpoint for third-party apps, and the SDK does not wire them up. Treat subscriptions as undocumented. Do not ship against them.

**Webhooks.** The supported real-time path. POST to a public HTTPS endpoint with HMAC-SHA256 signature. Requires infrastructure we don't want to run for a desktop app.

**Polling.** What we'll do. `issues(orderBy: updatedAt, filter: { updatedAt: { gt: <lastSync> } })` every 30-60 seconds. `notifications` on the same cadence. Heavy rollups (cycles, projects) on a 5-10 minute timer. Well within rate budget for a single user.

### Gotchas

- GraphQL can 200 with partial data plus an `errors` array. Always check it.
- `includeArchived: false` is the default everywhere. Historical queries need `includeArchived: true`.
- `orderBy` only supports `createdAt` and `updatedAt`. Priority / due date / estimate sort is client-side.
- `Roadmap` is deprecated. Build against `Initiative`.
- Many schema fields marked `[Internal]` or `[ALPHA]`. Avoid (`activitySummary`, `suggestions`, `facets`, agent mode). They can disappear.
- `searchIssues`, `searchProjects`, `semanticSearch` are the newer unified search. Prefer these over the older `issueSearch` for command palette features.
- `issueSearch` with large `first` is notoriously slow.

## Part F: Feature catalog

Widgets that fit a menu bar popover, ranked by glance quality and implementation cost. All assume OAuth with `read` scope unless noted.

| # | Feature | What it does | API surface | Glance | Difficulty |
| --- | --- | --- | --- | --- | --- |
| 1 | Inbox badge | Menu bar icon shows unread count | `notificationsUnreadCount` | 10 | Easy |
| 2 | Notifications feed tab | Last N Linear notifications, grouped by category | `notifications` | 10 | Easy |
| 3 | My issues ribbon | Assigned to me, sorted by priority | `viewer.assignedIssues` with state filter | 10 | Easy |
| 4 | Active cycle progress | Per-team row, burndown sparkline, percent complete | `Team.activeCycle` + history arrays | 10 | Easy |
| 5 | Project health wall | Tile grid colored by health, dashed if stale | `projects(...)` with `health`, `lastUpdate.isStale` | 9 | Easy |
| 6 | Overdue hit list | Overdue issues I own, grouped by days overdue | `issues(filter: { dueDate: { lt: "P0D" } })` | 9 | Easy |
| 7 | SLA alarm | Issues with `slaBreachesAt` near, live countdown | `slaBreachesAt`, `slaStatus` | 9 | Easy |
| 8 | Upcoming milestones | Next five, sorted by `targetDate` | `projectMilestones` | 9 | Easy |
| 9 | Stale project warning | Projects with stale or at-risk updates | `Project.lastUpdate { isStale, health }` | 8 | Easy |
| 10 | Mentions-only filter | Just @mentions from last 24h | `notifications(filter: { category: { eq: "mentions" } })` | 9 | Easy |
| 11 | Triage backlog | Per-team triage count, hover tooltip | `issues(filter: { state: { type: { eq: "triage" } } })` | 9 | Easy |
| 12 | Focus mode | Toggle that filters to Urgent + assigned + due today | Client filter composition | 10 | Easy |
| 13 | Team pulse sparkline | Completed-scope velocity across last six cycles | `Team.cycles(last: 6).completedScopeHistory` | 8 | Medium |
| 14 | Review queue | Issues in "In Review" state assigned to me | `issues(filter: { state: { name: ... } })` | 8 | Easy |
| 15 | Quick-create | ⌘N pops title field, creates issue in pinned team | `issueCreate` mutation, needs `issues:create` | 8 | Medium |
| 16 | Cycle time histogram | Tiny bar chart of last 20 completed issues | `issues(filter: { cycleTime: { null: false } })` | 7 | Medium |
| 17 | Customer signal row | Top 5 issues by `customerTicketCount` | `customerTicketCount`, `needs` | 7 | Medium |
| 18 | Initiative drill-in | Click initiative, see child projects with health dots | `initiatives { projects { health, progress } }` | 7 | Medium |
| 19 | Attachment activity | GitHub PR / Slack thread updates on watched issues | `Issue.attachments { sourceType }` | 7 | Medium |
| 20 | Workload heatmap | Row per team member, tile colored by in-progress estimate sum | `team.members.assignedIssues.estimate` | 8 | Medium |

## Part G: Top five if we only shipped five

1. **Inbox badge on the menu bar icon.** One scalar, constant visibility, instant glance value.
2. **Notifications feed as the primary tab.** This is the activity surface you actually want. Replace or complement the existing Recent.
3. **My Issues.** Open issues assigned to me, priority-sorted, with state dots and due badges. Pure `viewer.assignedIssues` call.
4. **Active cycle progress.** One row per team you're on. Shows cycle name, percent complete, tiny burndown sparkline. Zero client aggregation — the arrays are pre-computed.
5. **Project health wall.** Grid of project tiles colored by `health`, dashed border when `lastUpdate.isStale`. Takes two seconds to read.

These five are all cheap queries, all fit a 360px-wide popover, and together they cover the "what do I need to know right now" question for an engineering leader.

### My recommended tab structure for Linear Bar 2.0

- **Inbox** (new, primary). Notifications. Replaces the current Favorites-first experience.
- **My Issues** (new). `viewer.assignedIssues` with a small focus-mode toggle.
- **Recent** (your ask). The four-way `isMe` filter query from Part C, ordered by `updatedAt`.
- **Dashboard** (new). Cycles + project health + milestones + stale projects. Probably collapsible sections.
- **Search**. Keep the existing `searchIssues` flow. Maybe add `semanticSearch` for a natural-language mode later.
- **Favorites**. Demote to a settings-level thing or a sidebar. Not a top-level tab.

## Part H: Open questions

Things to decide before we start wiring:

1. **Do we ship quick-create in 2.0?** Requires `issues:create` OAuth scope. Adds a keyboard shortcut dimension and a "which team / project is default" setting.
2. **How much of the Dashboard tab fits in the popover vs. a drill-in?** Project health can be 12+ tiles. If we overflow, do we scroll or paginate?
3. **Do we want desktop notifications for mentions and SLA breaches?** Would require a permission prompt and a local `UNUserNotificationCenter` integration. mail-notifier does this for new mail.
4. **Focus mode scope.** Does it filter tabs to "Urgent + due today + assigned" only, or also dim the menu bar icon color?
5. **Per-team pinning.** If I'm on six teams, I probably only care about three for the active-cycle widget. Settings toggle?
6. **Multi-workspace.** Current app already supports multiple Linear accounts (visible via the color bar on rows). Does the Dashboard aggregate across accounts or show one at a time?

Once we have answers to these, we can pin down the UI in Paper and go.

---

*Last updated 2026-04-23. Source: Linear GraphQL schema at `linear/linear` on GitHub, plus the official developer docs at `linear.app/developers`. When in doubt, the schema wins.*
