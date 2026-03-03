import AppKit

/// Manages the menu bar status item and its icon state
@MainActor
class MenuBarManager {
    private(set) var statusItem: NSStatusItem?

    func setup(target: AnyObject, action: Selector) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            if let image = NSImage(systemSymbolName: "checkmark.circle", accessibilityDescription: "IssueBar") {
                image.isTemplate = true
                button.image = image
            } else {
                button.title = "L"
            }

            button.action = action
            button.target = target

            updateIcon()
        }
    }

    func updateIcon() {
        guard let button = statusItem?.button else { return }

        #if DEBUG
        if CommandLine.arguments.contains("--uitesting") {
            if let image = NSImage(systemSymbolName: "checkmark.circle.fill", accessibilityDescription: "IssueBar") {
                image.isTemplate = true
                button.image = image
            }
            return
        }
        #endif

        let hasAuthIssues = AppSettings.shared.accounts.contains { $0.authStatus != .valid }

        if hasAuthIssues {
            if let image = NSImage(systemSymbolName: "exclamationmark.triangle", accessibilityDescription: "IssueBar - Authentication Issue") {
                image.isTemplate = true
                button.image = image
            }
        } else if AppSettings.shared.accounts.isEmpty {
            if let image = NSImage(systemSymbolName: "checkmark.circle", accessibilityDescription: "IssueBar") {
                image.isTemplate = true
                button.image = image
            }
        } else {
            if let image = NSImage(systemSymbolName: "checkmark.circle.fill", accessibilityDescription: "IssueBar") {
                image.isTemplate = true
                button.image = image
            }
        }
    }
}
