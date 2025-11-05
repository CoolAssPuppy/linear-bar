# LinearBar

A beautiful macOS menu bar app for quick access to your Linear workspace. View favorites, recently updated items, and search across issues, projects, and initiatives without leaving your workflow.

## Features

- **Quick Access**: Three-panel interface with smooth navigation
  - Favorites: View your starred items from Linear
  - Recently Updated: Filter by items you created or team items
  - Search: Fast, debounced search across your workspace

- **Multiple Accounts**: Support for multiple Linear accounts with color coding
- **OAuth Authentication**: Secure OAuth 2.0 flow with Linear
- **iCloud Sync**: Settings and account preferences sync across devices
- **Native macOS**: Built with SwiftUI, follows Apple Human Interface Guidelines
- **Menu Bar Only**: Lightweight, lives in your menu bar

## Requirements

- macOS 13.0 (Ventura) or later
- Xcode 15.0 or later (for building)
- Linear account
- Active internet connection

## Installation

### From Source

1. Clone the repository:
   ```bash
   cd /Users/prashant/Developer/linear-bar
   ```

2. Open the project in Xcode:
   ```bash
   open LinearBar.xcodeproj
   ```

3. Configure Linear OAuth Application:
   - Go to Linear Settings → API → OAuth Applications
   - Create a new OAuth application
   - Set the redirect URI to: `linearbar://oauth/callback`
   - Copy the Client ID and Client Secret

4. Update OAuth credentials in `LinearBar/Services/LinearAuthService.swift`:
   ```swift
   private let clientId = "YOUR_LINEAR_CLIENT_ID"
   private let clientSecret = "YOUR_LINEAR_CLIENT_SECRET"
   ```

5. Configure code signing:
   - Select the LinearBar target in Xcode
   - Go to Signing & Capabilities
   - Select your development team
   - Ensure the bundle identifier is unique (e.g., `com.yourname.linearbar`)

6. Build and run the app (Cmd+R)

## First Launch Setup

1. **Sign In to Linear**:
   - Click the LinearBar icon in your menu bar
   - The popover will prompt you to add a Linear account
   - Or open Settings → Accounts → Add Linear Account
   - Your browser will open for OAuth authorization
   - Approve the connection
   - You'll be redirected back to LinearBar

2. **Configure Preferences**:
   - Open Settings (gear icon in popover)
   - Choose default view mode (My Items or Team Items)
   - Set refresh interval
   - Enable launch at login if desired

3. **Add Multiple Accounts** (Optional):
   - Go to Settings → Accounts
   - Click "Add Linear Account"
   - Assign unique colors to each account for easy identification

## Usage

### Main Interface

Click the LinearBar icon in your menu bar to open the popover:

- **Favorites Tab**: Shows your 10 most recently updated favorite items
- **Recently Updated Tab**:
  - Toggle between "Me" (items you created) and "Team" (items from selected team)
  - Select team from dropdown when in Team mode
- **Search Tab**:
  - Type to search across issues, projects, and initiatives
  - Results appear after 500ms of typing (debounced)
  - Shows up to 10 combined results

### Click Any Item

Clicking an item opens it in:
- Linear desktop app (if installed)
- Your default browser (if app not installed)

### Settings

Access via the gear icon in the popover header:

1. **Accounts Tab**:
   - View connected Linear accounts
   - Add new accounts
   - Change account colors (paint palette icon)
   - Remove accounts
   - Re-authenticate if needed

2. **Preferences Tab**:
   - Default View: Choose between "My Items" or "Team Items"
   - Refresh Interval: Manual, 5min, 15min, 30min, or 1 hour
   - Launch at Login: Start LinearBar when you log in

3. **About Tab**:
   - App version and build information

## Architecture

```
LinearBar/
├── App/
│   ├── LinearBarApp.swift       # App entry point
│   └── AppDelegate.swift        # Menu bar setup, URL handling
├── Models/
│   ├── LinearAccount.swift      # Account model
│   └── LinearTypes.swift        # Issue, Project, Initiative, Team models
├── Views/
│   ├── MenuBarView.swift        # Main popover with tabs
│   ├── FavoritesView.swift      # Favorites tab
│   ├── RecentlyUpdatedView.swift # Recently updated tab
│   ├── SearchView.swift         # Search tab
│   ├── SettingsView.swift       # Settings window
│   └── ItemRow.swift            # Reusable item row component
├── Services/
│   ├── LinearAPI.swift          # GraphQL API client
│   ├── LinearAuthService.swift  # OAuth flow
│   ├── KeychainService.swift    # Secure token storage
│   └── AppSettings.swift        # Settings with iCloud sync
└── Resources/
    ├── Info.plist              # App configuration
    ├── LinearBar.entitlements  # Sandbox & iCloud entitlements
    ├── PrivacyInfo.xcprivacy   # Privacy manifest
    └── Assets.xcassets/        # App icons

## Security

- **OAuth Tokens**: Stored securely in macOS Keychain
- **App Sandbox**: Runs in Apple's App Sandbox for security
- **Network Only**: Only requests network access, no file system access
- **No Analytics**: No tracking or data collection
- **iCloud Sync**: Settings only (not tokens) sync via iCloud Key-Value Store

## Troubleshooting

### Authentication Issues

**Problem**: "Sign in required" message appears

**Solutions**:
1. Go to Settings → Accounts
2. Click "Sign In" next to the affected account
3. Complete OAuth flow again
4. If issues persist, remove and re-add the account

### Menu Bar Icon Shows Warning

**Problem**: Triangle warning icon in menu bar

**Solution**: One or more accounts need re-authentication. Open Settings → Accounts to reconnect.

### No Items Appearing

**Problem**: Tabs show "No items" even though you have items in Linear

**Solutions**:
1. Check authentication in Settings → Accounts
2. Verify refresh interval isn't set to "Manual Only"
3. Click the refresh button if available
4. Check internet connection
5. Verify items exist in your Linear workspace

### Search Not Working

**Problem**: Search returns no results

**Solutions**:
1. Try different search terms
2. Ensure you're authenticated
3. Check internet connection
4. Linear API may be rate-limited (wait a few minutes)

### iCloud Sync Issues

**Problem**: Settings not syncing between devices

**Solutions**:
1. Ensure iCloud Drive is enabled on all devices
2. Check iCloud storage isn't full
3. Wait a few minutes for sync to occur
4. Sign out and back into iCloud

## Development

### Prerequisites

- Xcode 15.0+
- macOS 13.0+
- Swift 5.9+

### Building

```bash
# Clone the repository
git clone <repository-url>
cd linear-bar

# Open in Xcode
open LinearBar.xcodeproj

# Build
xcodebuild -project LinearBar.xcodeproj -scheme LinearBar build
```

### Testing

Currently, the app does not include automated tests. Manual testing checklist:

- [ ] OAuth flow completes successfully
- [ ] Favorites load correctly
- [ ] Recently Updated works in both Me and Team modes
- [ ] Search returns relevant results
- [ ] Settings persist across app restarts
- [ ] Multiple accounts work correctly
- [ ] Account colors display properly
- [ ] Items open in Linear when clicked
- [ ] iCloud sync works between devices

### Code Quality

The codebase follows:
- Swift API Design Guidelines
- Apple Human Interface Guidelines
- MVVM architecture patterns
- SwiftUI best practices
- Comprehensive error handling

## Privacy

LinearBar:
- Accesses your Linear data via OAuth
- Stores OAuth tokens in Keychain
- Syncs settings (not tokens) via iCloud
- Does not collect analytics
- Does not track usage
- Does not share data with third parties

See `PrivacyInfo.xcprivacy` for detailed privacy manifest.

## Roadmap

Potential future enhancements:
- [ ] Create issues from menu bar
- [ ] Quick actions (mark complete, change status)
- [ ] Keyboard navigation and shortcuts
- [ ] Custom filters
- [ ] Notifications for updates
- [ ] Multiple workspace support
- [ ] Sparkle auto-updater

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

[Specify your license here]

## Credits

Built with:
- Swift & SwiftUI
- Linear GraphQL API
- macOS Keychain Services
- iCloud Key-Value Store

Inspired by the simplicity and elegance of Linear's own design philosophy.

## Support

For issues, questions, or feature requests:
- Open an issue on GitHub
- Check existing issues first
- Provide detailed steps to reproduce any bugs

## Acknowledgments

- Linear team for their excellent API and documentation
- Meeting-Notifier app for UI/UX inspiration
- Apple for SwiftUI and developer tools
