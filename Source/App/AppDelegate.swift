import AppKit
import SwiftUI
import KeyboardShortcuts

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private let menuBarManager = MenuBarManager()
    private let popoverManager = PopoverManager()
    private let tokenScheduler = TokenRefreshScheduler()
    private let inboxStore = UnreadInboxStore.shared
    /// The single main window that hosts `LinearMainView` (sidebar + content
    /// + drawer overlay). Replaces the previous standalone Settings NSWindow.
    private var mainWindow: NSWindow?

    /// Validation tasks in flight. `applicationWillTerminate` cancels these;
    /// each task removes itself on completion so the array can't grow
    /// unbounded over a long session.
    private var inFlightValidationTasks: [UUID: Task<Void, Never>] = [:]

    private func launchValidationTask() {
        let id = UUID()
        let task = Task { @MainActor in
            defer { self.inFlightValidationTasks.removeValue(forKey: id) }
            await LinearAuthService.shared.validateAllAccountTokens()
        }
        inFlightValidationTasks[id] = task
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
            return
        }

        LoginItemController.migrateLegacyPreference()
        Telemetry.setup()
        menuBarManager.setup(target: self, action: #selector(menuBarButtonClicked))
        popoverManager.setup()
        KeyboardShortcuts.onKeyUp(for: .toggleLinearBar) { [weak self] in
            Task { @MainActor in self?.menuBarButtonClicked() }
        }
        NSApp.setActivationPolicy(.accessory)

        Telemetry.capture(.appLaunched)
        reportUpdateInstalledIfNeeded()

        tokenScheduler.onValidationComplete = { [weak self] in
            self?.menuBarManager.updateIcon()
        }

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )

        AppLogger.info("Linear Bar launched successfully", log: AppLogger.app)

        #if DEBUG
        if CommandLine.arguments.contains("--uitesting") {
            setupTestDataForUITesting()
        }
        #endif

        // Note: we intentionally do NOT register a kAEGetURL handler. OAuth
        // callbacks arrive via ASWebAuthenticationSession (callbackURLScheme)
        // which intercepts them without needing the scheme registered on the
        // app's AppleEvent manager. Removing this handler also removes an
        // external deep-link attack surface — the linearbar:// URL type has
        // been stripped from Info.plist for the same reason.

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSettingsRequest),
            name: .settingsRequested,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMainWindowRequest),
            name: .mainWindowRequested,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAccountsDidUpdate),
            name: .accountsDidUpdate,
            object: nil
        )

        #if DEBUG
        if !CommandLine.arguments.contains("--uitesting") {
            launchValidationTask()
            tokenScheduler.start()
            inboxStore.start()
        }
        #else
        launchValidationTask()
        tokenScheduler.start()
        inboxStore.start()
        #endif
    }

    func applicationWillTerminate(_ notification: Notification) {
        AppLogger.info("Linear Bar terminating", log: AppLogger.app)

        // Stop the periodic token refresh timer.
        tokenScheduler.stop()
        inboxStore.stop()
        menuBarManager.tearDown()

        // Cancel any in-flight validation tasks we launched so they don't
        // keep running past termination.
        for task in inFlightValidationTasks.values {
            task.cancel()
        }
        inFlightValidationTasks.removeAll()

        // Tear down the iCloud KVS observer so we don't leak it.
        AppSettings.shared.teardown()

        // Remove the popover's global mouse-down monitor if one is installed.
        popoverManager.tearDown()

        // Stop listening for wake and notification-center observers we added.
        // AppDelegate is the process-wide singleton; applicationWillTerminate
        // is the functional equivalent of deinit here.
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        // swiftlint:disable:next notification_center_detachment
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func handleWake(_ notification: Notification) {
        AppLogger.info("System woke from sleep - restarting token refresh timer", log: AppLogger.app)
        tokenScheduler.stop()
        tokenScheduler.start()

        launchValidationTask()
    }

    // MARK: - Actions

    @objc private func menuBarButtonClicked() {
        guard menuBarManager.statusItem?.button != nil else { return }

        if popoverManager.isShown {
            popoverManager.close()
        } else if let button = menuBarManager.statusItem?.button {
            popoverManager.show(relativeTo: button)
            Telemetry.capture(.menuOpened)
        }
    }

    /// Fires a `update.installed` event the first time a new build launches
    /// against a different `CFBundleShortVersionString` than the previous
    /// run. Silent on first-ever launch (no prior version stored). Lives
    /// alongside the `app.launched` fan-out so every release self-reports
    /// adoption without needing a Sparkle delegate.
    private func reportUpdateInstalledIfNeeded() {
        let key = "com.strategicnerds.LinearBar.telemetry.lastLaunchedVersion"
        let defaults = UserDefaults.standard
        let current = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        let previous = defaults.string(forKey: key)
        defaults.set(current, forKey: key)

        guard let previous, !previous.isEmpty, previous != current else { return }
        Telemetry.capture(.updateInstalled, properties: ["from": previous, "to": current])
    }

    // MARK: - Main window + Settings drawer

    /// Posting `.settingsRequested` from the popover gear (or elsewhere) lands
    /// here. We open the single main window and then post
    /// `.openSettingsDrawer`, which `LinearMainView` listens for and uses to
    /// toggle the drawer.
    /// Popover bottom bar "macwindow" button: surface the main window
    /// without the settings drawer.
    @objc private func handleMainWindowRequest() {
        popoverManager.close()
        openMainWindow()
    }

    @objc private func handleSettingsRequest() {
        popoverManager.close()
        openMainWindow()
        Task { @MainActor in
            // Wait one runloop tick so the window is key and MainView has
            // mounted its `.onReceive(…)` before we fire the toggle.
            try? await Task.sleep(nanoseconds: 50_000_000)
            NotificationCenter.default.post(name: .openSettingsDrawer, object: nil)
        }
    }

    /// Creates (or focuses) the single main window that hosts `LinearMainView`.
    /// The window uses a transparent titlebar + full-size content view so
    /// the sidebar and content read edge-to-edge.
    @objc private func openMainWindow() {
        // Stay .accessory — we never want a dock icon, even while the main
        // window is open. .accessory apps can still own standard windows;
        // makeKeyAndOrderFront + activate is enough to focus them.
        NSApp.activate(ignoringOtherApps: true)

        if let existingWindow = mainWindow {
            existingWindow.makeKeyAndOrderFront(nil)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1040, height: 680),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.contentView = NSHostingView(rootView: LinearMainViewWrapper())
        window.title = "Menu Bar for Linear"
        window.toolbar = nil
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isReleasedWhenClosed = false
        window.center()
        window.makeKeyAndOrderFront(nil)
        window.delegate = self

        mainWindow = window
    }

    @objc private func handleAccountsDidUpdate() {
        Task { @MainActor in
            menuBarManager.updateIcon()
        }
    }

    // MARK: - UI Testing Support

    #if DEBUG
    private func setupTestDataForUITesting() {
        print("Setting up test data for UI testing (AI Ski Goggles Co.)")

        let testAccount = LinearAccount(
            email: "sarah@aiskigoggles.ai",
            name: "Sarah Chen",
            organizationSlug: "aigoggles",
            isEnabled: true,
            authStatus: .valid,
            color: "#5E6AD2"
        )

        AppSettings.shared.accounts = [testAccount]
        NotificationCenter.default.post(name: .accountsDidUpdate, object: nil)

        print("Test data loaded successfully")
    }
    #endif
}

// MARK: - Window Delegate

extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        if let window = notification.object as? NSWindow, window == mainWindow {
            mainWindow = nil
        }
    }
}

// MARK: - Main view wrapper

/// Small wrapper so `@State var selection` is owned outside the NSWindow's
/// content view and persists while the window lives.
private struct LinearMainViewWrapper: View {
    @State private var selection: String?

    var body: some View {
        LinearMainView(selection: $selection)
    }
}
