import AppKit
import AuthenticationServices

// MARK: - ASWebAuthenticationPresentationContextProviding

extension LinearAuthService: ASWebAuthenticationPresentationContextProviding {
    nonisolated func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return MainActor.assumeIsolated {
            if let window = NSApplication.shared.keyWindow {
                return window
            }
            return NSApplication.shared.windows.first ?? NSWindow()
        }
    }
}
