import AppKit
import SwiftUI

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private let menuBarManager = MenuBarManager()
    private let popoverManager = PopoverManager()
    private let tokenScheduler = TokenRefreshScheduler()
    private var settingsWindow: NSWindow?

    /// In-flight token-validation tasks we launched. Tracked so that
    /// `applicationWillTerminate` can cancel them instead of leaving the
    /// process to tear them down mid-flight.
    private var inFlightValidationTasks: [Task<Void, Never>] = []

    private func launchValidationTask() {
        let task = Task { @MainActor in
            await LinearAuthService.shared.validateAllAccountTokens()
        }
        inFlightValidationTasks.append(task)
        // Opportunistically drop tasks that have already finished so the
        // array doesn't grow unbounded over a long session.
        inFlightValidationTasks.removeAll { $0.isCancelled }
    }

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
            launchValidationTask()
            tokenScheduler.start()
        }
        #else
        launchValidationTask()
        tokenScheduler.start()
        #endif
    }

    func applicationWillTerminate(_ notification: Notification) {
        AppLogger.info("Linear Bar terminating", log: AppLogger.app)

        // Stop the periodic token refresh timer.
        tokenScheduler.stop()

        // Cancel any in-flight validation tasks we launched so they don't
        // keep running past termination.
        for task in inFlightValidationTasks {
            task.cancel()
        }
        inFlightValidationTasks.removeAll()

        // Tear down the iCloud KVS observer so we don't leak it.
        AppSettings.shared.teardown()

        // Remove the popover's global mouse-down monitor if one is installed.
        popoverManager.tearDown()

        // Stop listening for wake and notification-center observers we added.
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Crash Handling

    private func setupCrashHandling() {
        NSSetUncaughtExceptionHandler { exception in
            // NSSetUncaughtExceptionHandler runs on a regular thread (not
            // inside a signal handler), so OSLog is safe to call here.
            AppLogger.fault("Uncaught exception: \(exception.name.rawValue) - \(exception.reason ?? "unknown")")
            AppLogger.fault("Stack trace: \(exception.callStackSymbols.joined(separator: "\n"))")
        }

        // Raw POSIX signal handlers run in async-signal context: almost no
        // Foundation/OSLog APIs are safe to call from here because they can
        // malloc, take locks, or call back into the signalled thread and
        // deadlock. Instead, write a short marker to a fixed path using only
        // async-signal-safe syscalls (open/write/close), then re-raise the
        // default handler so the process still dumps and terminates.
        signal(SIGABRT, AppDelegate.handleFatalSignal)
        signal(SIGSEGV, AppDelegate.handleFatalSignal)
    }

    /// C function pointer handler (must be @convention(c), no captures).
    /// Must only call async-signal-safe functions. See sigaction(2) on macOS:
    /// https://man7.org/linux/man-pages/man7/signal-safety.7.html — on Darwin,
    /// open(2), write(2), close(2), signal(2) and raise(3) are safe.
    /// OSLog is NOT safe (it can allocate and take locks).
    private static let handleFatalSignal: @convention(c) (Int32) -> Void = { signalNumber in
        // String literals passed to C functions as `UnsafePointer<CChar>` are
        // null-terminated automatically by the Swift compiler, which makes this
        // the simplest safe way to call open(2) from a signal handler.
        let fd = open("/tmp/linearbar-last-crash", O_WRONLY | O_CREAT | O_TRUNC, 0o644)
        if fd >= 0 {
            let message: StaticString
            switch signalNumber {
            case SIGABRT: message = "linearbar-crash-SIGABRT\n"
            case SIGSEGV: message = "linearbar-crash-SIGSEGV\n"
            default:      message = "linearbar-crash-UNKNOWN\n"
            }
            message.withUTF8Buffer { buf in
                if let base = buf.baseAddress {
                    _ = write(fd, base, buf.count)
                }
            }
            _ = close(fd)
        }

        // Re-raise with the default handler so the process terminates and the
        // OS can still produce a crash report.
        signal(signalNumber, SIG_DFL)
        raise(signalNumber)
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
