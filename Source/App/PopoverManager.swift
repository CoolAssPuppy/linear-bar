import AppKit
import SwiftUI

/// Manages the popover shown from the menu bar
@MainActor
class PopoverManager: NSObject {
    private(set) var popover: NSPopover?
    private var eventMonitor: Any?

    func setup() {
        let popover = NSPopover()
        popover.contentViewController = NSHostingController(rootView: MenuBarView())
        popover.behavior = .transient
        popover.delegate = self
        self.popover = popover
    }

    func show(relativeTo button: NSStatusBarButton) {
        popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        NSApp.activate(ignoringOtherApps: true)
        popover?.contentViewController?.view.window?.makeKey()
        startMonitoringForClicksOutside()
    }

    func close() {
        popover?.performClose(nil)
        stopMonitoringForClicksOutside()
    }

    /// Force-removes the global event monitor regardless of popover state.
    /// Called during app termination so we never leave a dangling monitor
    /// when the transient popover is closed by the system rather than by us.
    func tearDown() {
        stopMonitoringForClicksOutside()
    }

    var isShown: Bool {
        popover?.isShown == true
    }

    // MARK: - Click Outside Monitoring

    private func startMonitoringForClicksOutside() {
        // Defensive: if a monitor is already installed (e.g. show() called
        // twice without a matching close()), remove it before installing
        // a new one. Otherwise every mouse event fires the handler twice.
        stopMonitoringForClicksOutside()

        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if self.isShown {
                    self.close()
                }
            }
        }
    }

    private func stopMonitoringForClicksOutside() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
}

// MARK: - NSPopoverDelegate

extension PopoverManager: NSPopoverDelegate {
    // A .transient popover can be dismissed by the system (focus loss,
    // app deactivation, termination) without our close() ever being called.
    // Tear down the global mouse monitor here so it cannot leak.
    nonisolated func popoverDidClose(_ notification: Notification) {
        Task { @MainActor [weak self] in
            self?.stopMonitoringForClicksOutside()
        }
    }
}
