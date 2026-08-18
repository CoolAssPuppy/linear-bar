# Linear Bar reliability and codebase work

## Release 2.2.10

- [x] Review the final diff for credentials and generated files.
- [ ] Commit the completed fixes on a release branch.
- [ ] Merge the release branch into main.
- [ ] Run the signed and notarized 2.2.10 release with “Bug fixes”.
- [ ] Verify the live DMG and Sparkle feed.
- [ ] Commit the version and appcast changes.

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
