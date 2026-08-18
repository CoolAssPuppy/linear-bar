# Linear query and utility plan

Date: 2026-08-18

## Product rule

Every app view must say exactly what its data means. A view based on assignment, creation, subscription, comments, notifications, or `updatedAt` cannot claim to be viewing history.

Linear documents a recent-issues list in its own clients. The public GraphQL API does not expose that private list.

- **Recent**: workspace issues, projects, and initiatives ordered by `updatedAt`. This is implemented now.
- **Related activity**: issues assigned to, created by, subscribed to, or commented on by the viewer. This can be added as a separate preset.

## Common user jobs

This ranking is an inference from Linear's main product views, documented filters, display options, and recommended custom views. It is a product priority list, not Linear usage telemetry.

| Rank | User job | Useful result | Best source |
| --- | --- | --- | --- |
| 1 | Decide what to work on next | Urgent, SLA-bound, blocked, cycle, and other active assigned issues | `viewer.assignedIssues` plus issue fields |
| 2 | Respond to people | Mentions, assignments, reviews, comments, and status changes | `notifications` |
| 3 | Find something already known | Exact identifier, title, project, or document search | Search queries |
| 4 | Reopen recent work | Items recently updated in the workspace | Issues, projects, and initiatives ordered by `updatedAt` |
| 5 | Watch deadlines | Overdue, due soon, SLA risk, and upcoming milestones | Issue and milestone filters |
| 6 | Triage incoming work | Unassigned triage issues, customer requests, and SLA risk | Issue filters by team and state type |
| 7 | Check delivery health | Active cycle progress, at-risk projects, stale updates, and milestones | Cycle and project fields |
| 8 | Review a team | Blockers, work without an owner, work in review, and cycle scope changes | Issue relations and cycle data |
| 9 | Track customer demand | Issues with linked customer tickets or customer needs | Customer fields and relations |
| 10 | Reuse a personal workflow | Favorite and saved custom views | Favorites and custom views |

## Presets to add

### Personal focus

1. **Do next**
   - Assigned to viewer
   - Active workflow states
   - Groups in this order: urgent, SLA risk, blocked, due soon, current cycle, other active
   - Sorts each group by priority, due date, then last update

2. **Due soon**
   - Assigned to viewer
   - Due today or within seven days
   - Excludes completed and canceled states

3. **Blocked**
   - Assigned to viewer or in selected teams
   - `hasBlockedByRelations` is true

4. **Waiting on me**
   - Review notifications, mentions, assignments, and replies
   - Unread first

5. **Created by me**
   - `viewer.createdIssues`
   - Last created first

6. **Subscribed**
   - Viewer is a subscriber
   - Last updated first

### Team operations

1. **Triage now**
   - Selected teams
   - State type is `triage`
   - Unassigned first, then urgent and SLA risk

2. **Needs an owner**
   - Active issues in selected teams
   - Assignee is null

3. **Review queue**
   - Selected teams
   - Started state matching a configured review state
   - Oldest update first

4. **Cycle risk**
   - Current-cycle issues that are blocked, overdue, urgent, or not started near cycle end

5. **Scope added late**
   - Current cycle
   - `addedToCycleAt` after the cycle start plus 24 hours

### Product and leadership

1. **Projects at risk**
   - Health is at risk or off track
   - Active projects first

2. **Stale project updates**
   - Active projects where `lastUpdate.isStale` is true

3. **Upcoming milestones**
   - Target date within 14 or 30 days
   - Earliest date first

4. **Customer pressure**
   - Active issues with customer tickets or customer needs
   - Highest customer count first

5. **Initiative health**
   - Active initiatives with child project health and progress

## Interaction design

Add a compact query switcher above each result list:

- A preset picker with a short name and result count
- Team chips when the preset supports team scope
- A single sort control
- A pin action that adds the preset to the tab strip
- A clear empty state that repeats the active conditions

The first version should use fixed, tested presets. A later version can provide a sentence field such as “blocked issues on iOS due this week.” Parse that input into a limited local query model, show the resulting conditions as chips, and require confirmation before saving. Do not send arbitrary generated GraphQL to Linear.

## Technical design

Create one typed model shared by presets and user-saved queries:

```swift
struct IssueQueryDefinition: Codable, Hashable, Identifiable {
    let id: UUID
    var name: String
    var teamIds: Set<String>
    var ownership: OwnershipFilter
    var stateTypes: Set<WorkflowStateType>
    var priorities: Set<Int>
    var dateRule: DateRule?
    var relationRule: RelationRule?
    var sort: IssueSort
}
```

Each definition should have:

- A GraphQL filter builder with encoded variables
- A local sort for fields Linear cannot sort on the server
- A cache policy and refresh reason
- A result cap and cursor
- An account and workspace scope
- A user-facing explanation generated from the typed conditions
- Behavior tests for the filter, sort, and empty-state text

Use small GraphQL requests with explicit page sizes. Record request count, GraphQL complexity headers, result count, duration, and failure category without recording query text, item text, URLs, workspace names, or user identity.

## Delivery order

### Phase 1: High-frequency presets

- Add Do next, Due soon, Blocked, Waiting on me, Triage now, and Projects at risk.
- Add a pinned-preset row.
- Keep Recent as the workspace's most recently updated work.
- Add Related activity as a separate API preset.

### Phase 2: Saved query model

- Add the typed query definition and filter builder.
- Save personal presets locally and optionally sync their definitions through iCloud.
- Add team, state, priority, label, cycle, project, subscriber, relation, and date conditions.

### Phase 3: Team and product views

- Add cycle risk, needs an owner, scope added late, stale updates, upcoming milestones, and customer pressure.
- Add a compact detail view explaining why an item matched.

### Phase 4: Sentence input

- Map common phrases to the typed query model.
- Show parsed conditions before running the query.
- Fall back to the visual condition editor when a phrase is ambiguous.

## Success measures

- Time from menu click to opening the intended item
- Preset opens per active user
- Percentage of sessions that use search after a preset returns results
- Empty-result rate per preset
- Request latency, error rate, rate-limit rate, and GraphQL complexity
- Pinned-preset retention after 7 and 30 days

No measure may contain issue content, URLs, names, email addresses, workspace names, or raw search text.

## API limits that shape the product

- The API is GraphQL and supports filtering, pagination, `updatedAt` ordering, notifications, favorites, issues, projects, initiatives, documents, cycles, milestones, customers, and history on individual issues.
- General connections do not support every sort used in Linear's UI. Priority, due date, and several product-specific rankings require local sorting.
- Issue history is reached through each issue. A workspace-wide change feed built from history would require too many requests.
- Webhooks are the supported update path for hosted integrations. A local menu app should refresh visible data and use a conservative background interval.
- GraphQL rate-limit failures return HTTP 400 with `extensions.code = RATELIMITED`. The client now recognizes this code.

## References

- [Linear search](https://linear.app/docs/search)
- [Linear My issues](https://linear.app/docs/my-issues)
- [Linear filters](https://linear.app/docs/filters)
- [Linear custom views](https://linear.app/docs/custom-views)
- [Linear display options](https://linear.app/docs/display-options)
- [Linear GraphQL API](https://linear.app/developers/graphql)
- [Linear API rate limits](https://linear.app/developers/rate-limiting)
