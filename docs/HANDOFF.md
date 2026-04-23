# Linear Bar 2.0 handoff

Pick up here. Everything below is current as of the last commit on `newui`.

## Where we are

Branch `newui` in `/Users/prashant/Developer/mac-apps/linear-bar/`, eight commits ahead of `main`:

```
82eb92e Convert Settings to drawer-over-MainView pattern (1d)
1f01a4e Harden OAuth: add CSRF state, remove dead URL scheme, private log bodies
4da397f Stability hardening and StoreKit removal (1e + 1f)
45543d4 Port nerdsui visual framework from mail-notifier
bf2c270 Point Sparkle SUPublicEDKey at shared Strategic Nerds key
45e6912 Set Sparkle public key for Linear Bar
f6bdfe1 Bootstrap Linear Bar infrastructure (xcodegen, Sparkle, release flow)
bd6de14 Add Linear API capability reference for the 2.0 rework
```

**Build:** `xcodebuild -project LinearBar.xcodeproj -scheme LinearBar -configuration Debug -derivedDataPath build/DerivedData -allowProvisioningUpdates build` → green.

## Done

- Repo and local folder renamed `issue-bar` → `linear-bar`. GitHub repo also renamed.
- xcodegen config at `project.yml` is the source of truth. `LinearBar.xcodeproj` is generated and gitignored.
- Bundle `com.strategicnerds.LinearBarApp`. URL scheme `linearbar` was registered but is now removed (OAuth uses ASWebAuthenticationSession without needing Info.plist registration). Sandbox off. Hardened runtime on. iCloud KVS entitlement preserved.
- Swift Package deps: Sparkle 2.6+, KeyboardShortcuts 1.0+, KeychainAccess 4.0+, LaunchAtLogin-Modern 1.0+.
- Sparkle Ed25519 key pair matches the shared Strategic Nerds key (same value as mail-notifier / meeting-notifier). SUPublicEDKey in `Source/Resources/Info.plist` is live. Private key lives in Keychain under `com.strategicnerds.LinearBarApp`. A copy is in Doppler `linear-bar/prd` as `SPARKLE_PRIVATE_KEY`.
- Release scripts at `scripts/release.sh` `scripts/build-dmg.sh` `scripts/debug.sh` `scripts/export-options.plist`. `SPARKLE.md` documents key generation and the release flow.
- Dub shortlink `https://coolasspuppy.com/linear-bar-updates` redirects to `https://downloads.strategicnerds.com/apps/linear-bar/appcast.xml`. Appcast skeleton at `dist/appcast.xml`.
- Doppler `linear-bar/prd` has CLOUDFLARE_ACCOUNT_ID, CLOUDFLARE_API_TOKEN, R2_BUCKET_NAME, R2_PUBLIC_BASE_URL, SPARKLE_APP_SPECIFIC_PASSWORD, SPARKLE_PRIVATE_KEY. Release script defaults DOPPLER_PROJECT=agent-server and should be run with `DOPPLER_PROJECT=linear-bar ./scripts/release.sh …` or patched to default to linear-bar.
- Nerdsui visual framework ported: `Source/Views/Theme.swift`, `Source/Models/ThemeStore.swift`, `Source/Views/Components/SharedComponents.swift`, `Source/Services/UpdaterManager.swift`, `Source/Views/SettingsDrawer.swift`. All retrieved verbatim from mail-notifier except typography. 9 themes including Chapel (slate + amethyst) as the project's default.
- All linear-bar views retrofitted onto theme tokens: MenuBarView, ItemRow, IssueContentView, ProjectContentView, InitiativeContentView, Badges, StatusIcons, FavoritesView, RecentlyUpdatedView, SearchView, state views (Empty/Error/Loading/NoAccount).
- MenuBarView popover has HeaderBar / content / BottomBar matching mail-notifier, with `ThemeStrip()` in the BottomBar between two Spacers.
- StoreKit tip jar removed (StoreKitManager.swift, CoffeeView.swift, Configuration.storekit all gone). Support card replaces it with gradient "Buy me a coffee" Link to Venmo and outlined "Star on GitHub" Link.
- Stability hardening: iCloud KVS observer teardown, PopoverManager NSEvent monitor defensive teardown, TokenRefreshScheduler timer reset on restart, in-flight Task cancellation on terminate, async-signal-safe SIGABRT/SIGSEGV handlers.
- OAuth CSRF: `state` parameter with 32 bytes of SecRandomCopyBytes entropy, verified in callback. Dead `linearbar://` URL scheme removed from Info.plist and AppDelegate. Network error bodies logged with `privateError` instead of `error`.
- MainView + Sidebar + AccountView + WelcomeView built on the mail-notifier template. Drawer overlay with Settings content. Settings gear triggers: (a) from popover gear — opens main window then posts `.openSettingsDrawer` after 50ms; (b) from sidebar gear — toggles `isSettingsOpen` directly; (c) `⌘,` — bound to the sidebar gear button while main window is key.

## Paper design state

File "Linear Bar" in Paper has eight artboards documenting every screen:
- Popover - Inbox (primary tab, category filters, notification rows)
- Popover - My Issues (priority-grouped issue rows, Focus toggle)
- Popover - Recent (Today / Yesterday groupings)
- Popover - Pulse (active cycle cards with burndown sparklines, Project Health list, Upcoming milestones)
- Popover - Search (search input + scope chips + results)
- Popover - Welcome (used as the menu bar dropdown when no accounts exist)
- Main Window - Accounts (sidebar + per-workspace detail pane)
- Main Window - Settings Drawer (drawer-over-main-window)
- Menu Bar Icon States (quiet / unread / SLA alert / syncing / re-auth / offline)

Design tokens: Chapel Dark palette, slate (#0B0C10 background, #13141A surface) + amethyst (#7B8BDE primary, #5E6AD2 primaryDeep). Inter + JetBrains Mono.

## Still to do

These are the remaining commits. Each should be its own commit followed by `/simplify`, `/clean-and-refactor`, and `/security-review` per the user's preference.

### 1. Menu bar icon state rendering (small, half-commit)
Wire `MenuBarManager.updateIcon()` to produce the six icon states from the Paper "Menu Bar Icon States" artboard. Currently shows three SF Symbols (exclamationmark.triangle / checkmark.circle / checkmark.circle.fill). Replace with a custom NSImage that composites the Linear glyph with optional unread count overlay and optional SLA-alert red dot. States: quiet, unread (with count), urgent (red dot), syncing (dimmed + spinner), re-auth (orange X), offline (slash). Use `NSImage.Drawing` or a template PDF + `NSImage.lockFocus`.

### 2. Popover tabs per Paper designs
Five tabs live in the popover. MenuBarView currently renders the HeaderBar / BottomBar shell but the tab content is the pre-existing FavoritesView / RecentlyUpdatedView / SearchView. Replace each with its Paper design.

#### a. Inbox tab (new feature)
Highest priority — it is the new primary tab. Paper artboard "Popover - Inbox".
- New: `Source/Views/Popover/InboxView.swift`.
- New GraphQL query in `Source/Services/LinearAPI/LinearAPI+Notifications.swift` calling `notifications(first: 50, filter: { readAt: { null: true } })` with `NotificationCategory` discrimination. See `docs/LINEAR-CAPABILITIES.md` Part C for the query shape.
- Fetch `notificationsUnreadCount` for the menu bar badge count.
- Render rows by category: mentions, assignments, reviews, status changes, project updates, SLA alerts.
- Filter chips at the top: All, Mentions, Assigned, Reviews, SLA.
- Today / Yesterday section dividers.

#### b. My Issues tab
Paper artboard "Popover - My Issues". Mostly a restyle of the existing FavoritesView or a new `MyIssuesView`.
- Query `viewer.assignedIssues(filter: { state: { type: { nin: ["completed", "canceled"] } } })`.
- Group rows by priority (Urgent, High, Medium, Low) with colored section dividers.
- Focus toggle that filters to priority 1 + due-today + assigned.

#### c. Recent tab
Paper artboard "Popover - Recent". Reuse RecentlyUpdatedView, restyle.
- Query the "touched by me" shape from `docs/LINEAR-CAPABILITIES.md` Part C.
- Group by Today / Yesterday / Earlier.
- View selector: Created by me / Assigned to me / Team — matches current tri-state but renders differently.

#### d. Search tab
Paper artboard "Popover - Search". Reuse SearchView, restyle.
- Scope chips: Issues / Projects / Documents / Comments.
- Keyboard shortcut pill (⌘K).
- `searchIssues` for Issues, `searchProjects` for Projects, `searchDocuments` for Documents.

#### e. Pulse tab (biggest new feature)
Paper artboard "Popover - Pulse".
- New `Source/Views/Popover/PulseView.swift`.
- Active cycle cards: query `team.activeCycle { progress, scopeHistory, completedScopeHistory, startsAt, endsAt }` for each team the viewer is on. Render as a card with big % complete number, sparkline burndown, progress bar segmented by state, stats row.
- Project health wall: query `projects(filter: { status: { type: { eq: "started" } } }) { health, progress, lastUpdate { isStale } }`. Render as editorial list sorted by risk (off-track first, then at-risk, then on-track collapsed).
- Upcoming milestones: query `projectMilestones(filter: { targetDate: { lt: "P2W" } })` sorted by targetDate. Render as two or three date-chip rows.

### 3. Welcome as menu bar dropdown
When `AppSettings.shared.accounts.isEmpty`, the popover should render the WelcomeView (already built for the main window). Hook this into MenuBarView's content switch.

### 4. Workspace accent color hex input
Paper artboard "Main Window - Accounts" shows a hex input next to the preset swatches. AccountView's Identity card currently only has preset swatches. Add a `TextField` bound to `account.color` (String) with validation for `#RRGGBB` pattern.

### 5. First release (1g)
Once the tabs ship:
1. Bump version in `project.yml` to 2.0.0 (already there) and CURRENT_PROJECT_VERSION accordingly.
2. Run `DOPPLER_PROJECT=linear-bar ./scripts/release.sh 2.0.0 "<li>Rebuilt off the App Store.</li><li>New Inbox, Pulse, and settings drawer.</li>"`.
3. Script handles notarization + DMG + Sparkle signing + R2 upload + appcast update.
4. Commit `project.yml` and `dist/appcast.xml`.

### Nice-to-haves flagged by security review
- Commit `Package.resolved` to a tracked location (currently lives inside gitignored `.xcodeproj`). Copy it out on release or add a CI step to preserve it.
- Per-app Sparkle key rotation. All three Strategic Nerds apps currently share one Ed25519 key. Generate a linear-bar-specific key later and push to Doppler as SPARKLE_PRIVATE_KEY_LINEARBAR.

## How to start the fresh session

1. `cd /Users/prashant/Developer/mac-apps/linear-bar`
2. `git status` should be clean except for `.claude/` (which is the worktree cache from this session's agents — can be deleted or left alone).
3. `git log --oneline -8` should match the commits above.
4. Open this file `docs/HANDOFF.md`.
5. Open `docs/LINEAR-CAPABILITIES.md` for the GraphQL query patterns you'll need.
6. Open the Paper file "Linear Bar" for the visual reference.
7. Pick up from Still to do §1 (menu bar icon states) or §2 (popover tabs) depending on energy.

## Guardrails from the user

- Do not freelance UI — copy mail-notifier's patterns verbatim. Study mail-notifier before deviating. The user has pushed back hard on invented variations.
- Every major addition gets a commit, then `/simplify`, `/clean-and-refactor`, and `/security-review`.
- Background agents writing to the main tree caused problems in this session. If using subagents, prefer foreground runs for Swift work, or verify worktree isolation explicitly before spawning.
- No emojis, no em-dashes, sentence case for headers.
- Never push without explicit authorization.
