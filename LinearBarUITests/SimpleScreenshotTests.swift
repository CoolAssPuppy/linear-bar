import XCTest

/// Simplified screenshot tests for LinearBar menu bar app
/// Tests capture screenshots of Favorites, Recent, Search tabs, and Settings
@MainActor
class SimpleScreenshotTests: XCTestCase {

    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        app = XCUIApplication()
        app.launchArguments.append("--uitesting")

        setupSnapshot(app)
        app.launch()

        // Give the app time to load test data and show menu bar icon
        print("⏱️ Waiting 5 seconds for app to initialize...")
        sleep(5)

        print("✅ App should be ready now")
        print("📍 Check your menu bar for the LinearBar icon (checkmark circle)")
    }

    override func tearDown() {
        app.terminate()
        super.tearDown()
    }

    /// Main screenshot capture test
    /// INSTRUCTIONS:
    /// 1. Run this test (Cmd+U or Product > Test)
    /// 2. When the app launches, MANUALLY click the LinearBar menu bar icon to open the dropdown
    /// 3. The test will automatically capture screenshots as it navigates through tabs
    func testCaptureAllScreenshots() {
        print("🎬 Starting LinearBar screenshot capture...")
        print("📌 Please click the LinearBar menu bar icon now!")
        print("⏱️ You have 10 seconds to click the icon...")

        // Wait for user to manually open the dropdown
        sleep(10)

        // Debug: Check what windows are visible
        print("🔍 Debug: Checking visible windows...")
        print("   App windows count: \(app.windows.count)")
        for i in 0..<app.windows.count {
            let window = app.windows.element(boundBy: i)
            print("   Window \(i): exists=\(window.exists), frame=\(window.frame)")
        }

        // Screenshot 1: Favorites tab (should be default)
        print("📸 Capturing Favorites tab...")
        snapshot("01FavoritesTab")
        sleep(1)

        // Navigate to Recent tab
        print("🔍 Navigating to Recent tab...")
        if clickTab(named: "Recent") {
            sleep(2)
            print("📸 Capturing Recent tab...")
            snapshot("02RecentTab")
        } else {
            print("⚠️  Could not find Recent tab automatically")
            print("📌 Please click the Recent tab now!")
            sleep(5)
            snapshot("02RecentTab")
        }

        // Navigate to Search tab
        print("🔍 Navigating to Search tab...")
        if clickTab(named: "Search") {
            sleep(2)
            print("📸 Capturing Search tab...")
            snapshot("03SearchTab")
        } else {
            print("⚠️  Could not find Search tab automatically")
            print("📌 Please click the Search tab now!")
            sleep(5)
            snapshot("03SearchTab")
        }

        // Look for the Settings button and click it
        print("🔍 Looking for Settings button...")
        if let settingsButton = findSettingsButton() {
            print("✅ Found Settings button, clicking...")
            settingsButton.click()
            sleep(2)
        } else {
            print("⚠️  Could not find Settings button automatically")
            print("📌 Please click the Settings gear icon now!")
            sleep(5)
        }

        // Wait for settings window
        sleep(2)

        // Debug: Check windows again
        print("🔍 Debug: Checking windows after settings opened...")
        print("   App windows count: \(app.windows.count)")

        // Screenshot 4: Settings - Accounts tab (default)
        print("📸 Capturing Accounts tab...")
        snapshot("04SettingsAccounts")

        // Navigate to Setup tab
        print("🔍 Navigating to Setup tab...")
        if clickTab(named: "Setup") {
            sleep(1)
            print("📸 Capturing Setup tab...")
            snapshot("05SettingsSetup")
        } else {
            print("⚠️  Please manually click the Setup tab")
            sleep(5)
            snapshot("05SettingsSetup")
        }

        print("✅ Screenshot capture complete!")
        print("📂 Screenshots saved to: ~/Library/Caches/tools.fastlane/")
    }

    // MARK: - Helper Methods

    private func findSettingsButton() -> XCUIElement? {
        // Try different ways to find the Settings button

        // Method 1: By accessibility identifier
        if app.buttons["settingsButton"].exists {
            return app.buttons["settingsButton"]
        }

        // Method 2: By label containing "Settings"
        let buttons = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Settings'"))
        if buttons.count > 0 {
            return buttons.firstMatch
        }

        // Method 3: By system image name (gear icon)
        let gearButtons = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'gear'"))
        if gearButtons.count > 0 {
            return gearButtons.firstMatch
        }

        return nil
    }

    private func clickTab(named tabName: String) -> Bool {
        // Try to find and click a tab

        // Method 1: Radio buttons (tabs in TabView appear as radio buttons)
        let radioButtons = app.radioButtons.matching(NSPredicate(format: "label CONTAINS[c] %@", tabName))
        if radioButtons.count > 0 {
            radioButtons.firstMatch.click()
            return true
        }

        // Method 2: Regular buttons
        let buttons = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", tabName))
        if buttons.count > 0 {
            buttons.firstMatch.click()
            return true
        }

        // Method 3: By accessibility identifier
        let identifierMap: [String: String] = [
            "Favorites": "favoritesTab",
            "Recent": "recentTab",
            "Search": "searchTab",
            "Accounts": "accountsTab",
            "Setup": "setupTab"
        ]

        if let identifier = identifierMap[tabName] {
            if app.radioButtons[identifier].exists {
                app.radioButtons[identifier].click()
                return true
            }
            if app.buttons[identifier].exists {
                app.buttons[identifier].click()
                return true
            }
        }

        return false
    }
}
