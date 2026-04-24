import Foundation
import SwiftUI

/// Lightweight publish-subscribe bus for transient toast messages shown
/// at the bottom of the popover. Centralized so any view — a deeply
/// nested row action, a background task completion — can request a
/// toast without threading a closure through.
@MainActor
final class ToastCenter: ObservableObject {
    static let shared = ToastCenter()

    /// Current message. `nil` when no toast is visible.
    @Published private(set) var message: String?

    private var dismissTask: Task<Void, Never>?

    private init() {}

    /// Shows `text` for `duration` seconds, replacing any in-flight toast.
    func show(_ text: String, duration: TimeInterval = 1.8) {
        dismissTask?.cancel()
        message = text

        dismissTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            guard !Task.isCancelled else { return }
            self?.message = nil
        }
    }
}
