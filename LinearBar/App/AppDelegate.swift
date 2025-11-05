import AppKit
import SwiftUI

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var settingsWindow: NSWindow?
    private var popover: NSPopover?
    private var eventMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        setupPopover()
        NSApp.setActivationPolicy(.accessory)

        // Register URL handler for OAuth callbacks
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleGetURLEvent(_:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )

        // Listen for settings requests
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSettingsRequest),
            name: .settingsRequested,
            object: nil
        )

        // Listen for account updates to refresh menu bar icon
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAccountsDidUpdate),
            name: .accountsDidUpdate,
            object: nil
        )
    }

    // MARK: - Menu Bar Setup

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            // Use a template icon that works in both light and dark mode
            if let image = NSImage(systemSymbolName: "checkmark.square", accessibilityDescription: "LinearBar") {
                image.isTemplate = true
                button.image = image
            } else {
                button.title = "L"
            }

            button.action = #selector(menuBarButtonClicked)
            button.target = self

            // Check if we have accounts with auth issues
            updateMenuBarIcon()
        }
    }

    private func updateMenuBarIcon() {
        guard let button = statusItem?.button else { return }

        // Check if any account has auth issues
        let hasAuthIssues = AppSettings.shared.accounts.contains { $0.authStatus != .valid }

        if hasAuthIssues {
            // Show warning icon
            if let image = NSImage(systemSymbolName: "exclamationmark.triangle", accessibilityDescription: "LinearBar - Authentication Issue") {
                image.isTemplate = true
                button.image = image
            }
        } else if AppSettings.shared.accounts.isEmpty {
            // Show default icon
            if let image = NSImage(systemSymbolName: "checkmark.square", accessibilityDescription: "LinearBar") {
                image.isTemplate = true
                button.image = image
            }
        } else {
            // Show connected icon
            if let image = NSImage(systemSymbolName: "checkmark.square.fill", accessibilityDescription: "LinearBar") {
                image.isTemplate = true
                button.image = image
            }
        }
    }

    private func setupPopover() {
        popover = NSPopover()
        popover?.contentViewController = NSHostingController(rootView: MenuBarView())
        popover?.behavior = .transient
    }

    // MARK: - Actions

    @objc private func menuBarButtonClicked() {
        guard statusItem?.button != nil else { return }

        if popover?.isShown == true {
            closePopover()
        } else {
            showPopover()
        }
    }

    private func showPopover() {
        guard let button = statusItem?.button else { return }
        popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)

        // Activate the app and make the popover window key to give it focus
        NSApp.activate(ignoringOtherApps: true)
        popover?.contentViewController?.view.window?.makeKey()

        startMonitoringForClicksOutsidePopover()
    }

    private func closePopover() {
        popover?.performClose(nil)
        stopMonitoringForClicksOutsidePopover()
    }

    private func startMonitoringForClicksOutsidePopover() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            if self?.popover?.isShown == true {
                self?.closePopover()
            }
        }
    }

    private func stopMonitoringForClicksOutsidePopover() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    // MARK: - URL Handling

    @objc func handleGetURLEvent(_ event: NSAppleEventDescriptor, withReplyEvent replyEvent: NSAppleEventDescriptor) {
        guard let urlString = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue,
              let url = URL(string: urlString) else {
            return
        }

        Task { @MainActor in
            _ = LinearAuthService.shared.handleCallback(url: url)
        }
    }

    // MARK: - Settings

    @objc private func handleSettingsRequest() {
        closePopover()
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

            // Check if there's an existing window
            for window in NSApp.windows {
                if window.styleMask.contains(.borderless) {
                    continue
                }
                self.settingsWindow = window
                window.delegate = self
                window.makeKeyAndOrderFront(nil)
                return
            }

            // Create new settings window
            let settingsView = SettingsView()

            let newWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 500, height: 600),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            newWindow.contentView = NSHostingView(rootView: settingsView)
            newWindow.title = "LinearBar Settings"
            newWindow.isReleasedWhenClosed = false
            newWindow.center()
            newWindow.makeKeyAndOrderFront(nil)

            self.settingsWindow = newWindow
            newWindow.delegate = self
        }
    }

    @objc private func handleAccountsDidUpdate() {
        Task { @MainActor in
            updateMenuBarIcon()
        }
    }
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
