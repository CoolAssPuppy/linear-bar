import AppKit

/// Shared clipboard helper. `NSPasteboard.general.clearContents()` +
/// `setString(_:forType: .string)` is the idiomatic string copy on
/// macOS, but callers that forget `clearContents()` leak prior
/// contents across types. Centralizing the pair avoids that and
/// keeps copy sites single-line.
extension NSPasteboard {
    static func copyString(_ string: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(string, forType: .string)
    }
}
