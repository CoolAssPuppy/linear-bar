# LinearBar

A native macOS menu bar app for quick access to your Linear workspace. View favorites, recently updated items, and search across issues, projects, and initiatives without leaving your workflow.

![macOS](https://img.shields.io/badge/macOS-13.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.9+-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## Features

- **Three-panel interface** with smooth tab navigation
  - **Favorites**: Your starred items from Linear
  - **Recent**: Filter by created, assigned, or team items
  - **Search**: Fast search across issues, projects, and initiatives

- **State-based icons**: Visual indicators matching Linear's design language
- **Smart filtering**: Hide completed or canceled items
- **OAuth authentication**: Secure OAuth 2.0 flow with Linear
- **Multi-account support**: Switch between Linear workspaces (planned)
- **iCloud sync**: Settings sync across your devices
- **Native macOS**: Built with SwiftUI, follows Apple HIG

## Quick Start

### 1. Clone the repository

```bash
git clone https://github.com/yourusername/linear-bar.git
cd linear-bar
```

### 2. Get Linear OAuth credentials

1. Go to [Linear Settings → API → OAuth Applications](https://linear.app/settings/api/applications/new)
2. Click **"Create new OAuth application"**
3. Fill in the details:
   - **Name**: LinearBar (or your preferred name)
   - **Callback URL**: `linearbar://oauth/callback`
   - **Scopes**: Select `read` (minimum required)
4. Click **Create**
5. Copy your **Client ID** and **Client Secret**

### 3. Configure credentials

Choose one of two methods:

#### Option A: Doppler (Recommended for teams)

```bash
# Install Doppler
brew install dopplerhq/cli/doppler

# Login and setup
doppler login
doppler setup

# Add your secrets
doppler secrets set LINEAR_CLIENT_ID="lin_oauth_xxxxx"
doppler secrets set LINEAR_CLIENT_SECRET="your_secret_here"

# Run Xcode with Doppler
doppler run -- open LinearBar.xcodeproj
```

#### Option B: Local file (Simple for solo dev)

1. Open `LinearBar/Services/LinearAuthSecrets.swift`
2. Replace the placeholder values:
   ```swift
   static let clientId = "YOUR_LINEAR_CLIENT_ID"
   static let clientSecret = "YOUR_LINEAR_CLIENT_SECRET"
   ```
3. This file is gitignored, so your secrets are safe

### 4. Build and run

1. Open `LinearBar.xcodeproj` in Xcode
2. Select your development team in **Signing & Capabilities**
3. Press **Cmd+R** to build and run
4. Click the menu bar icon and sign in to Linear

## Architecture

LinearBar follows MVVM architecture with clean separation of concerns:

```
LinearBar/
├── App/
│   ├── LinearBarApp.swift          # App entry point
│   └── AppDelegate.swift           # Menu bar lifecycle, URL handling
│
├── Models/
│   ├── LinearTypes.swift           # Issue, Project, Initiative, Team
│   └── LinearAccount.swift         # Multi-account support
│
├── Views/
│   ├── MenuBarView.swift           # Main popover container
│   ├── FavoritesView.swift         # Favorites tab
│   ├── RecentlyUpdatedView.swift   # Recent tab with filters
│   ├── SearchView.swift            # Search tab with debouncing
│   ├── SettingsView.swift          # Settings window
│   └── ItemRow.swift               # Reusable item component
│
├── Services/
│   ├── LinearAPI.swift             # GraphQL API client
│   ├── LinearAuthService.swift     # OAuth 2.0 flow
│   ├── KeychainService.swift       # Secure token storage
│   └── AppSettings.swift           # iCloud-synced settings
│
└── Resources/
    ├── LinearAuthSecrets.swift     # OAuth credentials (gitignored)
    └── Assets.xcassets/            # App icons
```

### Key Components

**LinearAPI**: GraphQL client for fetching issues, projects, initiatives, favorites, and teams. Handles pagination, error handling, and rate limiting.

**LinearAuthService**: OAuth 2.0 flow implementation with custom URL scheme (`linearbar://`). Supports Doppler environment variables for credential management.

**KeychainService**: Stores OAuth tokens securely in macOS Keychain. Tokens never touch disk or iCloud.

**AppSettings**: User preferences with iCloud Key-Value Store sync. Handles default views, filters, and refresh intervals.

## Usage

### Main Interface

Click the LinearBar icon in your menu bar:

- **Favorites**: Shows your favorited items from Linear
- **Recent**: Three sub-tabs for Created, Assigned, or Team items
- **Search**: Type to search (debounced 500ms)

Click any item to open it in Linear (app or browser).

### Settings

Access via the gear icon:

1. **Accounts**: Add/remove Linear accounts, re-authenticate
2. **Preferences**:
   - Default view and tab
   - Show/hide completed and canceled items
   - Refresh interval
   - Launch at login
3. **About**: Version and build info

### Creating Items

Click the **+** button to create:
- New Issue
- New Project
- New Initiative

Opens Linear's creation flow in your browser.

## Development

### Prerequisites

- macOS 13.0 (Ventura) or later
- Xcode 15.0 or later
- Swift 5.9 or later
- Linear account with OAuth app

### Building

```bash
# Clone and open
git clone <repository-url>
cd linear-bar
open LinearBar.xcodeproj

# Or build from command line
xcodebuild -scheme LinearBar -configuration Debug build
```

### Code Structure

- **MVVM pattern**: Views observe models via `@ObservedObject` and `@StateObject`
- **Async/await**: All API calls use modern Swift concurrency
- **Error handling**: Comprehensive error states and user feedback
- **Type safety**: Protocols for shared behavior (`LinearItem`)
- **Reusable components**: Shared row components, icon mapping, state normalization

## Security & Privacy

- **OAuth tokens**: Stored in macOS Keychain (never in code or iCloud)
- **App Sandbox**: Runs sandboxed with minimal permissions
- **No analytics**: Zero tracking or data collection
- **No third parties**: Only communicates with Linear's API
- **iCloud**: Only settings sync (not credentials)
- **Secrets management**: Doppler support for team environments

## Troubleshooting

**Authentication fails**: Check that your OAuth callback URL is exactly `linearbar://oauth/callback` in Linear settings.

**No items showing**: Verify authentication in Settings → Accounts. Check that you have items in Linear.

**Search not working**: Ensure you're authenticated and have network connectivity.

**Build errors**: Ensure you've configured `LinearAuthSecrets.swift` with valid credentials.

## Roadmap

Future enhancements (v0.2+):
- Quick actions (mark complete, change assignee)
- Keyboard shortcuts and navigation
- Custom filters and views
- Update notifications
- Assignee avatars
- Priority indicators

## Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Test thoroughly
4. Submit a PR with clear description

## License

MIT License - see LICENSE file for details

## Credits

Built with:
- Swift & SwiftUI
- [Linear GraphQL API](https://developers.linear.app/docs/graphql/working-with-the-graphql-api)
- macOS Keychain Services
- iCloud Key-Value Store
- [Doppler](https://doppler.com) for secrets management

Inspired by Linear's elegant design philosophy.

## Support

- Open an issue for bugs or feature requests
- Check existing issues before creating new ones
- Provide reproduction steps for bugs

---

**Version**: 0.1.0
**Status**: Active development
