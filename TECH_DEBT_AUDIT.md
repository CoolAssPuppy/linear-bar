# Linear Bar codebase audit

Date: 2026-08-18

## Result

No known critical or high-priority defect remains from this review. The reported login, hover, crash-reporting, and Recent problems were corrected. The review also fixed OAuth, URL handling, Keychain protection, rate-limit handling, telemetry consent, production sandboxing, test isolation, dead settings, and a vulnerable updater version.

The app now passes 61 behavior tests, strict SwiftLint with zero violations, a Debug build, a signed Release build, and Xcode static analysis.

## Reported problems

### Silent disappearance

The local macOS unified log contained this AppKit warning from Linear Bar:

`It's not legal to call -layoutSubtreeIfNeeded on a view which is already being laid out`

The issue rows added and removed a nested button during hover. That changed the SwiftUI tree while AppKit was laying out the menu. The row structure is now constant and copy actions live in context menus.

The previous signal handlers also called Foundation and file APIs from `SIGABRT` and `SIGSEGV` handlers. Those APIs are unsafe in a signal handler and can cause another failure while handling the first one. The handlers were removed. PostHog's PLCrashReporter integration now records native crashes when the user enables anonymous diagnostics.

No Apple crash report was present for the inspected installed build, so the historical failures cannot be assigned to one cause with certainty. The layout warning is direct evidence for the hover-related failure. Crash capture now provides evidence if another cause remains.

### Open at Login

The setting previously changed a saved Boolean and never changed the macOS login item. It now reads and updates `SMAppService.mainApp`, reports failures, and migrates the old preference once. Login state is kept out of iCloud because it belongs to one Mac.

### Recent

The old query ignored its date argument and returned issues created by or assigned to the viewer. That was unrelated to viewing history.

Linear's public GraphQL API does not expose the private recent-item list used by Linear's own clients. Recent now shows the latest issues, projects, and initiatives ordered by `updatedAt` in Linear. Team, type, and Time filters are applied consistently.

## Security corrections

| Finding | Resolution |
| --- | --- |
| OAuth code exchange included a client secret in a distributed desktop app | Removed the secret and added PKCE with SHA-256 plus state validation |
| OAuth response logging could expose code fragments | Removed response-fragment logging and kept errors content-free |
| Untrusted IDs could add path levels to Linear URLs | Added strict path-segment encoding and host checks |
| Keychain entries used a weaker default accessibility class | Tokens now use `WhenUnlockedThisDeviceOnly` on creation and update |
| Account fragments appeared in token logs | Removed account and email fragments |
| Anonymous diagnostics defaulted on | Default changed to off and crash capture follows consent |
| Telemetry used unsafe cross-actor state | Moved telemetry state to the main actor |
| Sparkle 2.9.1 had published security advisories | Pinned Sparkle 2.9.4 |
| Production app lacked App Sandbox | Enabled it with outbound network access and Sparkle's documented helper permissions |
| Package versions could drift | Pinned direct packages to exact reviewed versions |

The Release build's signed entitlements were inspected. It contains App Sandbox, network client, iCloud key-value storage, and Sparkle's two installer helper names. The local Release build uses an Apple Development profile, so the release script must still create and notarize the distribution archive.

## Reliability and correctness corrections

- GraphQL errors now decode `extensions.code` and treat Linear's HTTP 400 `RATELIMITED` response as a rate limit.
- Login-item failures restore the real system state and show an error.
- The unread-count setting now changes the menu bar icon.
- The global keyboard shortcut is connected during app startup.
- The status item is removed during shutdown.
- Production startup, timers, iCloud, Keychain, and analytics are skipped in the XCTest host.
- Debug settings allow hosted tests without weakening Release.
- Multiple-instance prevention applies to Release and does not block the test host.
- The README and API capability notes now match the app.

## Performance review

The app uses bounded GraphQL page sizes and a five-minute background refresh. Network calls are asynchronous, and the menu bar icon cache avoids repeated image rendering. Recent requests 50 issues, 30 projects, and 30 initiatives.

Recommended next changes:

1. Pause background refresh while the Mac is asleep or the user session is inactive.
2. Refresh visible tabs on demand and cache each preset separately.
3. Record duration, result count, rate-limit category, and GraphQL complexity headers without item content.
4. Move JSON encoding and decoding off the main actor when query presets increase request volume.
5. Add cursor pagination only to views where users ask for more than the first page.

## Readability and reuse review

The API code is already split by domain and the new login, PKCE, Recent, and URL rules are isolated and tested. Four older files remain too large:

| File | Lines | Planned split |
| --- | ---: | --- |
| `Source/Views/MenuBarView.swift` | 799 | window shell, tab selection, refresh state, keyboard actions |
| `Source/Services/TestDataProvider.swift` | 768 | one fixture factory per Linear domain |
| `Source/Views/AccountView.swift` | 584 | account summary, authorization, removal, workspace details |
| `Source/Models/ThemeStore.swift` | 442 | theme definitions, persistence, selection |

These are medium-priority restructuring tasks. They should be done one file at a time with behavior tests before each split. A broad rewrite would increase risk without changing user behavior.

The GraphQL variable layer also uses `[String: Any]`. Replace it with typed `Encodable` request values as the saved-query model is added. This will remove runtime shape errors and keep filter construction testable.

## Verification

- 63 tests passed with zero failures.
- SwiftLint checked 92 Swift files with zero violations.
- Debug build passed.
- Release static analysis passed.
- Signed Release build passed.
- Release entitlements were inspected.
- Property lists and entitlement files passed `plutil`.
- Direct dependencies resolved to Sparkle 2.9.4, KeyboardShortcuts 1.17.0, KeychainAccess 4.2.2, PostHog 3.56.0, and PLCrashReporter 1.12.2.

## References

- [Apple SMAppService](https://developer.apple.com/documentation/servicemanagement/smappservice)
- [Linear OAuth 2.0](https://linear.app/developers/oauth-2-0-authentication)
- [Linear GraphQL API](https://linear.app/developers/graphql)
- [Linear API rate limits](https://linear.app/developers/rate-limiting)
- [Sparkle sandboxing](https://sparkle-project.org/documentation/sandboxing/)
- [Sparkle advisory GHSA-hg88-v3cw-3qrh](https://github.com/advisories/GHSA-hg88-v3cw-3qrh)
- [Sparkle advisory GHSA-g3hp-f6mg-559v](https://github.com/advisories/GHSA-g3hp-f6mg-559v)
