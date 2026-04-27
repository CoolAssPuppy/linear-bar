# Menu Bar for Linear

A native macOS menu bar app for quick access to your Linear workspace. View favorites, recently updated items, and search across issues, projects, and initiatives without leaving your workflow.

![macOS](https://img.shields.io/badge/macOS-13.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.9+-orange)
![License](https://img.shields.io/badge/license-Custom-green)

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
git clone https://github.com/coolasspuppy/linear-bar.git
cd linear-bar
```

### 2. Get Linear OAuth credentials

1. Go to [Linear Settings → API → OAuth Applications](https://linear.app/settings/api/applications/new)
2. Click **"Create new OAuth application"**
3. Fill in the details:
   - **Name**: Menu Bar for Linear (or your preferred name)
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

Menu Bar for Linear follows MVVM architecture with clean separation of concerns:

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

Click the Menu Bar for Linear icon in your menu bar:

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
git clone https://github.com/coolasspuppy/linear-bar.git
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

Custom Open Source License - see [LICENSE](LICENSE) file for details.

**TL;DR**: You can fork and customize for personal use, but you cannot distribute through the App Store without permission. This protects the official Menu Bar for Linear while keeping the code open for learning and personal projects.

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

## App Store Marketing

### App Name
Menu Bar for Linear

### Subtitle
Quick access to Linear from your menu bar

### Promotional Text (170 characters max)
Access your Linear issues, projects, and favorites instantly from your Mac's menu bar. Stay focused on what matters without switching windows.

### Description

Menu Bar for Linear brings Linear to your Mac's menu bar for instant access to your work items without disrupting your flow.

FEATURES

Quick Access
Open Menu Bar for Linear from your menu bar with a single click. View your favorites, recent issues, and projects without opening a browser tab.

Multiple Views
- Favorites: Your starred issues, projects, and initiatives at your fingertips
- Recent: Recently updated items sorted by activity
- Search: Find any issue or project across your workspace instantly

Multiple Account Support
Switch between different Linear workspaces seamlessly. Perfect for freelancers and team members working across multiple organizations.

Smart Filtering
- Show or hide completed items
- Filter out canceled issues
- Sort by creation date or last update
- Customize your view to match your workflow

iCloud Sync
Your preferences sync automatically across all your Macs via iCloud. Set it once, use it everywhere.

Security & Privacy
- Secure OAuth authentication
- Credentials stored safely in macOS Keychain
- No data collected or shared
- Open source for complete transparency

Native macOS Experience
Built natively for macOS with SwiftUI for a fast, responsive experience that feels right at home on your Mac.

PERFECT FOR

- Product managers tracking multiple initiatives
- Engineers managing sprint tasks
- Designers reviewing feedback
- Team leads monitoring project progress
- Anyone who wants faster access to Linear

GET STARTED

1. Connect your Linear account with secure OAuth
2. Choose your default view and preferences
3. Access your work from the menu bar anytime

Menu Bar for Linear respects your focus. No notifications, no interruptions - just quick access when you need it.

### Keywords (100 characters max)
Linear,issue tracker,project management,productivity,menu bar,task management,workflow,developer tools

### What's New (Version 1.0.0)

Initial release of Menu Bar for Linear

Features included in this first release:

- Quick access to Linear from your menu bar
- View favorites, recent items, and search your workspace
- Multiple Linear account support
- Secure OAuth authentication
- Smart filtering and sorting options
- iCloud sync for preferences across devices
- Native macOS design built with SwiftUI

We built Menu Bar for Linear to give you faster access to Linear without disrupting your workflow. Give it a try and let us know what you think.

### App Store Metadata

**Support URL**: https://github.com/coolasspuppy/linear-bar
**Privacy Policy URL**: https://github.com/coolasspuppy/linear-bar/blob/main/PRIVACY.md
**Copyright**: Copyright © 2025 Strategic Nerds, Inc. All rights reserved.
**Category**: Primary: Business / Secondary: Productivity
**Age Rating**: 4+

### Privacy Policy

Menu Bar for Linear Privacy Policy

Data Collection:
Menu Bar for Linear does not collect, store, or transmit any personal data to third parties.

Data Storage:
- Your Linear access tokens are stored securely in the macOS Keychain
- App preferences are stored locally and optionally synced via your iCloud account
- No analytics or tracking data is collected

Third-Party Services:
Menu Bar for Linear connects directly to Linear's API (api.linear.app) using OAuth authentication. Please refer to Linear's privacy policy for information about their data practices.

Open Source:
Menu Bar for Linear is open source software. You can review the complete source code at our GitHub repository.

Contact:
For privacy concerns or questions, please open an issue on our GitHub repository.

Last updated: January 2025

### App Review Notes

Menu Bar for Linear is a menu bar utility for macOS that provides quick access to the Linear project management platform.

Test Account Information:
- You will need a Linear account to test this app
- You can create a free Linear account at linear.app
- The app uses OAuth authentication with Linear's official API

OAuth Configuration:
- The app uses standard OAuth 2.0 flow with Linear
- Client ID and Secret are configured in the app
- Redirect URI: linearbar://oauth/callback

Key Features to Test:
1. Click the menu bar icon to open the dropdown
2. Add a Linear account via OAuth (requires Linear login)
3. Browse favorites, recent items, or use search
4. Click any item to open it in your browser
5. Configure preferences in the Settings tab

The app requires:
- macOS 13.0 or later
- Internet connection to access Linear API
- Linear account (free or paid)

All data is stored locally or in the user's iCloud account. No data is collected by the app developer.

---

**Version**: 0.1.0
**Status**: Active development
