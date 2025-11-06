# LinearBar Screenshot Generation Guide

This guide explains how to set up and run automated screenshot generation for App Store submissions using UI tests and Fastlane.

## Overview

LinearBar uses:
- **XCTest UI Tests** for automated navigation and interaction
- **Fastlane snapshot** for capturing and organizing screenshots
- **Test data** with funny but professional AI Ski Goggles company content

## Setup

### 1. Add UI Test Target to Xcode

The UI test files are already created in `LinearBar/LinearBarUITests/`, but you need to add the target to the Xcode project:

1. Open `LinearBar.xcodeproj` in Xcode
2. Select the project in the navigator
3. Click the "+" button at the bottom of the targets list
4. Select **macOS > Test > UI Testing Bundle**
5. Name it `LinearBarUITests`
6. Set the target to be tested: `LinearBar`
7. Click **Finish**

### 2. Add Test Files to Target

1. In Xcode's Project Navigator, locate these files:
   - `LinearBar/LinearBarUITests/SnapshotHelper.swift`
   - `LinearBar/LinearBarUITests/SimpleScreenshotTests.swift`

2. If they appear grayed out or not in the project:
   - Right-click on the `LinearBarUITests` folder
   - Select **Add Files to "LinearBar"...**
   - Navigate to `LinearBar/LinearBarUITests/`
   - Select both files
   - Ensure "Add to targets" checkbox for `LinearBarUITests` is checked
   - Click **Add**

3. Verify target membership:
   - Select each file
   - In the File Inspector (right sidebar), check that `LinearBarUITests` is checked under **Target Membership**

### 3. Add Test Data Provider to Main Target

The `TestDataProvider.swift` file needs to be in the main app target:

1. In Xcode, locate `LinearBar/Services/TestDataProvider.swift`
2. In the File Inspector, ensure it's added to the `LinearBar` target (NOT the UI test target)

## Running Screenshot Tests

### Method 1: Run from Xcode (Recommended for Testing)

1. In Xcode, select the scheme dropdown → **LinearBar**
2. Select **Product > Test** (or press `Cmd+U`)
3. Or click the test diamond icon next to `testCaptureAllScreenshots` in `SimpleScreenshotTests.swift`

**Important**: When the app launches:
1. **Manually click** the LinearBar menu bar icon (checkmark circle in the menu bar)
2. The test will automatically navigate through tabs and capture screenshots
3. When prompted, **manually click** the Settings gear icon
4. The test will capture the Settings screens

Screenshots will be saved to:
```
~/Library/Caches/tools.fastlane/
```

### Method 2: Run with Fastlane (For Production Screenshots)

```bash
cd /Users/prashant/Developer/linear-bar
bundle exec fastlane snapshot
```

This will:
- Build the app with UI tests
- Run the screenshot tests
- Save organized screenshots to `./fastlane/screenshots/`

## Test Data

The test data simulates a fictional **AI Ski Goggles Inc.** company with:

### Teams
- 🤖 ML Vision (MLVIS)
- ⚡ Hardware (HW)
- 📱 Product (PROD)
- 🥽 AR Experience (AR)

### Sample Issues (Funny but Professional)
- "Fix snowflake detection AI hallucinating penguins"
- "Battery drains faster in cold weather (obviously)"
- "Implement 'Are those clouds or avalanche risk?' detection"
- "Add friend detection to stop yelling at strangers"
- "Goggles fog up when user is too excited about powder"
- "Document: How to explain to investors why we need AI for skiing"
- "AR overlay shows 'You're doing great!' even during faceplant"

### Projects
- 🎿 Winter 2025 Launch
- 📱 Mobile App 2.0
- 🔬 Summer Product Research

### Initiatives
- "Become #1 AI Ski Goggle Company (there are dozens of us!)"
- "Expand to Snowboarding (controversial internally)"

## Screenshot Workflow

The test captures these screens in order:

1. **01FavoritesTab** - Favorites tab showing starred issues and projects
2. **02RecentTab** - Recent tab with recently updated issues
3. **03SearchTab** - Search tab (empty state or with results)
4. **04SettingsAccounts** - Settings window showing Accounts tab
5. **05SettingsSetup** - Settings window showing Setup/Preferences tab

## Customizing Test Data

To modify the test data:

1. Open `LinearBar/Services/TestDataProvider.swift`
2. Edit the methods:
   - `getFavorites()` - Favorite items shown in Favorites tab
   - `getRecentIssues()` - Issues shown in Recent and Search tabs
   - `getTeams()` - Teams available in the team selector
   - `getProjects()` - Projects
   - `getInitiatives()` - Initiatives

3. Test data uses the `--uitesting` launch argument, so it only appears during UI tests

## Troubleshooting

### Screenshots are blank or show wrong content

- Make sure you manually clicked the menu bar icon when the test started
- The test prints debug messages to the console - check for "Found X window(s)"
- Try running the test again with a delay to give more time for UI to load

### Test target not found

- Verify the UI test target is properly added in Xcode
- Check that the scheme includes the UI tests: Product → Scheme → Edit Scheme → Test
- Ensure `SimpleScreenshotTests.swift` has target membership in `LinearBarUITests`

### Test data not showing

- Verify `TestDataProvider.swift` is in the main `LinearBar` target
- Check that `--uitesting` launch argument is being passed (it's automatic in the test)
- Look for the debug log message: "🎬 Setting up test data for UI testing"

### Fastlane snapshot fails

- Make sure you've run `bundle install` to install Fastlane dependencies
- Update the `Snapfile` with the correct test target name if needed
- Run directly from Xcode first to verify tests work

## App Store Screenshot Requirements

For macOS App Store, you need screenshots for:

- **Required**: 1280 x 800 pixels (or larger up to 2560 x 1600)
- **Optional**: 1440 x 900, 2560 x 1600, 2880 x 1800

The screenshot tool captures at the app's natural size. You may need to crop/resize for App Store requirements:

```bash
# Resize screenshots to required dimensions
sips -Z 1280 ./fastlane/screenshots/en-US/*.png
```

## Next Steps

After capturing screenshots:

1. Review screenshots in `fastlane/screenshots/en-US/`
2. Edit/crop if needed for App Store requirements
3. Upload to App Store Connect via Fastlane or manually
4. Add captions and descriptions in App Store Connect

## Resources

- [Fastlane snapshot documentation](https://docs.fastlane.tools/actions/snapshot/)
- [XCTest UI Testing](https://developer.apple.com/documentation/xctest/user_interface_tests)
- [App Store Screenshot Specifications](https://developer.apple.com/help/app-store-connect/reference/screenshot-specifications/)
