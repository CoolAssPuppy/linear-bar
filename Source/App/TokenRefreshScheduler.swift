import Foundation

/// Manages periodic token validation and refresh
@MainActor
class TokenRefreshScheduler {
    private var timer: Timer?
    var onValidationComplete: (() -> Void)?

    func start() {
        // Ensure any previously scheduled timer is cancelled before we create
        // and retain a new one. Without this, back-to-back start() calls (or a
        // stop()+start() on wake) could leave a dangling RunLoop timer.
        timer?.invalidate()
        timer = nil

        let newTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                AppLogger.info("Periodic token validation triggered", log: AppLogger.auth)
                await LinearAuthService.shared.validateAllAccountTokens()
                self.onValidationComplete?()
            }
        }

        timer = newTimer
        RunLoop.main.add(newTimer, forMode: .common)
        AppLogger.info("Token refresh timer started", log: AppLogger.auth)
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        AppLogger.info("Token refresh timer stopped", log: AppLogger.auth)
    }
}
