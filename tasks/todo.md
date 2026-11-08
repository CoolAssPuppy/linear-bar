# Linear Bar reliability and codebase work

## UI cleanup (cleanup-ui)

### Theme selector follow-up
- [x] Replace the Appearance Picker with a compact theme name and color control that expands left on hover or click.
- [x] Keep each theme keyboard and VoiceOver accessible, and honor Reduce Motion.
- [x] Coordinate Xcode and live UI checks with the parent agent. Swift parsing and strict lint pass with zero violations.

No new isolated test is needed for this view-only interaction; verify it in the running Settings UI with mouse, keyboard, VoiceOver, and Reduce Motion.

### Release 2.3.0 plan
- [x] Run the complete local gate on the final UI source: tests, strict lint, Debug build, Release analysis, and live selector review.
- [x] Check signing, notarization, Sparkle, Doppler, and R2 prerequisites; compare local and live appcast versions.
- [x] Run `scripts/release.sh 2.3.0 "<li>Some UI cleanup.</li>"` after verification and release coordination.
- [x] Verify signed artifacts and the live appcast.
- [x] Commit the final source, version, and appcast changes, fast forward main, and push once.

Preflight: `agent-server` notary profile and Developer ID identity are available. The Sparkle keychain account exists, and Linear Bar's shipped public key matches Mail Notifier's. R2 credentials are in `linear-bar/prd`; the release script now uses that project. Archive, signature, and upload results are recorded below.

The current UI source passed 67 hosted tests, strict lint with zero violations, Debug build, and Release analysis on 2026-11-08. The user reviewed the UI and authorized release. Rerun the complete gate after any release-source edits before committing.

Release review: the final 2.3.0/build 32 files passed 67 hosted tests (`/tmp/linear-bar-release-final-test.log`, xcresult in `/tmp/linear-bar-ui-final-signed-derived/Logs/Test`), strict lint with zero violations (`/tmp/linear-bar-release-final-lint.log`), a Debug build (`/tmp/linear-bar-release-final-build.log`), and Release analysis (`/tmp/linear-bar-release-final-analyze.log`). The exported app and DMG pass signature and notarization checks. The live shortlink appcast shows 2.3.0/build 32 with `<li>Some UI cleanup.</li>`. Its R2 DMG returns 200 and 4,895,626 bytes, matching the local file.

### Plan
- [x] Simplify the popover footer while keeping refresh, window, Settings, theme, and Quit available.
- [x] Make Settings a single-column list and move theme choices there.
- [x] Reduce repeated first-run decoration and copy in the popover and main window.
- [x] Check keyboard labels and review the diff for behavior changes.
- [x] Inspect the changed UI in the running app and save screenshots.

### Review
- `xcodebuild test` passed 67 tests, SwiftLint found zero violations, the Debug build passed, and Release static analysis passed. Logs are in `/tmp/linear-bar-cleanup-{test,lint,build,analyze}.log`.
- Main window, Settings, and dropdown content screenshots are in `/Users/prashant/.codex/visualizations/2026/11/08/01a1b9c1-dfc3-7aa1-8a2e-b771e8dc5c85/screenshots`. The dropdown uses a temporary preview window with fictional test data; direct menu bar placement still needs checking. Preview code was removed, the normal build passed, and the installed app and saved settings were restored.

## Release 2.2.10

- [x] Review the final diff for credentials and generated files.
- [x] Commit the completed fixes on a release branch.
- [x] Merge the release branch into main.
- [x] Run the signed and notarized 2.2.10 release with “Bug fixes”.
- [x] Verify the live DMG and Sparkle feed.
- [x] Commit the version and appcast changes.

## Corrected DMG release

- [x] Replace Finder automation with a pinned Finder-free DMG builder.
- [x] Verify the standard background and Finder layout before upload.
- [x] Release 2.2.11 as build 30 with “Bug fixes”.
- [x] Verify the live DMG and Sparkle feed.
- [x] Commit the corrected release files on main.

## Inbox notification links

- [x] Add failing tests for common notification titles and target URLs.
- [x] Query Linear's common notification presentation fields.
- [x] Make every notification row show a useful title and open its target.
- [x] Verify lint, tests, build, and static analysis.

## Recent uses Linear activity

- [x] Add failing tests for Time and type filtering.
- [x] Query recently updated issues across the Linear workspace.
- [x] Restore recently updated projects and initiatives.
- [x] Rename Scope to Time and replace Anything I touched with All Time.
- [x] Remove local Recent storage and recording.
- [x] Run the complete verification suite.

## Execution plan

- [x] Map the app, recent changes, large files, and high-churn areas.
- [x] Trace the reported crash, hover, login-item, and Recent behavior.
- [x] Add failing regression tests for behavior that can be tested without UI automation.
- [x] Replace the saved login preference with the macOS login-item API.
- [x] Remove hover-time row hierarchy changes and nested buttons.
- [x] Enable persisted crash reports and abnormal-session diagnostics.
- [x] Correct Recent so every filter has real behavior and its copy states what the API can return.
- [x] Fix Debug XCTest settings, generated-project checks, and dependency pinning.
- [x] Address high-impact security, performance, error-handling, and maintainability findings.
- [x] Run SwiftLint, tests, build, static analysis, and release configuration checks.
- [x] Write the cited codebase audit and the Linear query product plan.

## Verification gates

- [x] SwiftLint reports no violations.
- [x] All behavior tests pass on macOS.
- [x] Debug build succeeds with warnings reviewed.
- [x] Static analyzer succeeds.
- [x] Login-item state is read from `SMAppService`.
- [x] Issue rows keep the same view structure before and during hover.
- [x] Recent does not claim to show artifacts viewed in Linear when the public API cannot return that history.
- [x] Crash reports persist across process death and are sent only when telemetry is enabled.

## Review

Completed on 2026-08-18.

- 63 tests passed with zero failures.
- SwiftLint found zero violations in 93 files.
- Debug and signed Release builds passed.
- Xcode static analysis passed.
- Recent now shows workspace issues, projects, and initiatives ordered by their latest Linear update.
- The Time filter offers All Time, Last 7 days, and Last 30 days. Team and type filters remain available.
- Inbox rows now use Linear's shared notification title, subtitle, and target URL.
- Release entitlements contain App Sandbox, network client, iCloud key-value storage, and Sparkle helper permissions.
- The remaining medium-priority restructuring work is listed in `TECH_DEBT_AUDIT.md`.
