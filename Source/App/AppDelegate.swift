import AppKit
import SwiftUI

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private let menuBarManager = MenuBarManager()
    private let popoverManager = PopoverManager()
    private let tokenScheduler = TokenRefreshScheduler()
    private var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupCrashHandling()
        menuBarManager.setup(target: self, action: #selector(menuBarButtonClicked))
        popoverManager.setup()
        NSApp.setActivationPolicy(.accessory)

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

        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleGetURLEvent(_:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSettingsRequest),
            name: .settingsRequested,
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
            Task {
                await LinearAuthService.shared.validateAllAccountTokens()
            }
            tokenScheduler.start()
        }
        #else
        Task {
            await LinearAuthService.shared.validateAllAccountTokens()
        }
        tokenScheduler.start()
        #endif
    }

    func applicationWillTerminate(_ notification: Notification) {
        AppLogger.info("Linear Bar terminating", log: AppLogger.app)
        tokenScheduler.stop()
    }

    // MARK: - Crash Handling

    private func setupCrashHandling() {
        NSSetUncaughtExceptionHandler { exception in
            AppLogger.fault("Uncaught exception: \(exception.name.rawValue) - \(exception.reason ?? "unknown")")
            AppLogger.fault("Stack trace: \(exception.callStackSymbols.joined(separator: "\n"))")
        }

        signal(SIGABRT) { _ in
            AppLogger.fault("Received SIGABRT signal")
        }
        signal(SIGSEGV) { _ in
            AppLogger.fault("Received SIGSEGV signal")
        }
    }

    @objc private func handleWake(_ notification: Notification) {
        AppLogger.info("System woke from sleep - restarting token refresh timer", log: AppLogger.app)
        tokenScheduler.stop()
        tokenScheduler.start()

        Task {
            await LinearAuthService.shared.validateAllAccountTokens()
        }
    }

    // MARK: - Actions

    @objc private func menuBarButtonClicked() {
        guard menuBarManager.statusItem?.button != nil else { return }

        if popoverManager.isShown {
            popoverManager.close()
        } else if let button = menuBarManager.statusItem?.button {
            popoverManager.show(relativeTo: button)
        }
    }

    // MARK: - URL Handling

    @objc func handleGetURLEvent(_ event: NSAppleEventDescriptor, withReplyEvent replyEvent: NSAppleEventDescriptor) {
        guard let urlString = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue,
              let url = URL(string: urlString) else {
            return
        }

        AppLogger.debug("Received URL: \(url.absoluteString)", log: AppLogger.auth)
    }

    // MARK: - Settings

    @objc private func handleSettingsRequest() {
        popoverManager.close()
        openSettings()
    }

    @objc private func openSettings() {
        NSApp.setActivationPolicy(.regular)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }

            NSApp.activate(ignoringOtherApps: true)

            if let existingWindow = self.settingsWindow {
                existingWindow.makeKeyAndOrderFront(nil)
                return
            }

            for window in NSApp.windows {
                if window.styleMask.contains(.borderless) {
                    continue
                }
                self.settingsWindow = window
                window.delegate = self
                window.makeKeyAndOrderFront(nil)
                return
            }

            let settingsView = SettingsView()

            let newWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 500, height: 600),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            newWindow.contentView = NSHostingView(rootView: settingsView)
            newWindow.title = "Linear Bar Settings"
            newWindow.isReleasedWhenClosed = false
            newWindow.center()
            newWindow.makeKeyAndOrderFront(nil)

            self.settingsWindow = newWindow
            newWindow.delegate = self
        }
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
        if let window = notification.object as? NSWindow, window == settingsWindow {
            settingsWindow = nil
            NSApp.setActivationPolicy(.accessory)
        }
    }
}
