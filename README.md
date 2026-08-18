# Menu Bar for Linear

A native macOS menu bar app for checking Linear without opening another full window.

## Features

- Inbox with unread notifications and category filters
- My Issues grouped by priority
- Issues, projects, and initiatives most recently updated in Linear
- Cycle progress, project health, and upcoming milestones
- Search across issues, projects, and documents
- Favorites and multiple Linear workspaces
- Global keyboard shortcut and Launch at Login
- Automatic updates through Sparkle

## Requirements

- macOS 14 or later
- Xcode 15 or later
- Swift 5.9 or later
- XcodeGen
- A Linear OAuth application with the `read` scope

## Set up the project

1. Create a Linear OAuth application in [Linear API settings](https://linear.app/settings/api/applications/new).
2. Set its callback URL to `linearbar://oauth/callback`.
3. Copy `Source/Services/LinearAuthSecrets.swift.template` to `Source/Services/LinearAuthSecrets.swift`.
4. Add the public OAuth client ID. The app uses OAuth PKCE and does not embed a client secret.
5. Generate the Xcode project and open it:

```bash
xcodegen generate
open LinearBar.xcodeproj
```

Select a development team in Xcode, then run the `LinearBar` scheme.

## Development checks

`project.yml` is the project source. Regenerate the Xcode project after changing it.

```bash
xcodegen generate
swiftlint lint --strict --no-cache
xcodebuild -project LinearBar.xcodeproj -scheme LinearBar -configuration Debug build
xcodebuild -project LinearBar.xcodeproj -scheme LinearBar -configuration Release analyze
```

The app tests are hosted by the macOS application. They can be run from Xcode with Product > Test or with `xcodebuild ... test` on a machine whose local development certificate is trusted.

## Code layout

```text
Source/
  App/                 App lifecycle, menu bar item, and popover
  Models/              Linear GraphQL response models and app state
  Services/            OAuth, Keychain, GraphQL, settings, and telemetry
  Utilities/           URL validation, formatting, and rendering helpers
  Views/               Main window and popover screens
Tests/                 Behavior tests
docs/                  API notes, product plans, and release guidance
project.yml            XcodeGen project definition
```

## Security and privacy

- OAuth uses state validation and PKCE with SHA-256.
- Access and refresh tokens stay in the macOS Keychain and do not sync through iCloud.
- Built URLs validate their scheme and host before opening.
- Anonymous diagnostics are off on a new install. Users can enable usage events and crash reports in Settings. Issue text, URLs, names, and email addresses are excluded.
- Connected workspaces and preferences can sync through iCloud. Tokens remain on each Mac.
- The app requests Linear's read-only OAuth scope.

## What Recent means

Linear's public API does not provide the private recently viewed list shown in Linear's own clients. Recent instead shows issues, projects, and initiatives ordered by their `updatedAt` value in Linear. Team, type, and Time filters narrow that result.

## Troubleshooting

- Authentication fails: confirm the callback URL is exactly `linearbar://oauth/callback` and the client ID matches the Linear OAuth application.
- Launch at Login needs approval: open System Settings > General > Login Items and allow Menu Bar for Linear.
- Empty views: confirm at least one workspace is enabled and its token is valid.
- Build errors after editing `project.yml`: run `xcodegen generate` again.

## License

Mozilla Public License 2.0. See [LICENSE](LICENSE).
