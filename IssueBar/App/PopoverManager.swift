import AppKit
import SwiftUI

/// Manages the popover shown from the menu bar
@MainActor
class PopoverManager {
    private(set) var popover: NSPopover?
    private var eventMonitor: Any?

    func setup() {
        popover = NSPopover()
        popover?.contentViewController = NSHostingController(rootView: MenuBarView())
        popover?.behavior = .transient
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

    var isShown: Bool {
        popover?.isShown == true
    }

    // MARK: - Click Outside Monitoring

    private func startMonitoringForClicksOutside() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            if self?.isShown == true {
                self?.close()
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
