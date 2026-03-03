import Foundation

extension LinearAuthService {

    /// Validates and proactively refreshes the access token for an account if needed
    /// Returns true if the account has valid credentials, false if re-authentication is required
    func validateAndRefreshToken(forAccount email: String) async -> Bool {
        AppLogger.privateInfo("Validating token for \(email)", log: AppLogger.auth)

        guard KeychainService.shared.retrieveAccessToken(forAccount: email) != nil else {
            AppLogger.privateError("No access token found for \(email)", log: AppLogger.auth)
            updateAccountAuthStatus(email: email, status: .needsAuth)
            return false
        }

        if KeychainService.shared.isTokenExpiringSoon(forAccount: email, bufferSeconds: 7200) {
            AppLogger.privateInfo("Token expiring soon for \(email), proactively refreshing", log: AppLogger.auth)
            do {
                _ = try await refreshAccessToken(forAccount: email)
                AppLogger.privateInfo("Proactive token refresh successful for \(email)", log: AppLogger.auth)
                updateAccountAuthStatus(email: email, status: .valid)
                return true
            } catch {
                AppLogger.privateError("Proactive token refresh failed for \(email): \(error.localizedDescription)", log: AppLogger.auth)
            }
        }

        guard let accessToken = KeychainService.shared.retrieveAccessToken(forAccount: email) else {
            AppLogger.privateError("No access token found for \(email) after refresh attempt", log: AppLogger.auth)
            updateAccountAuthStatus(email: email, status: .needsAuth)
            return false
        }

        do {
            _ = try await LinearAPI.shared.fetchViewer(accessToken: accessToken, accountEmail: email)
            AppLogger.privateInfo("Token is valid for \(email)", log: AppLogger.auth)
            updateAccountAuthStatus(email: email, status: .valid)
            return true
        } catch LinearError.authenticationRequired {
            AppLogger.privateError("Token validation failed for \(email) - authentication required", log: AppLogger.auth)
            updateAccountAuthStatus(email: email, status: .expired)
            return false
        } catch {
            AppLogger.privateError("Token validation error for \(email): \(error.localizedDescription)", log: AppLogger.auth)
            return true // Assume valid if it's just a network error
        }
    }

    /// Validates tokens for all accounts and updates their auth status
    func validateAllAccountTokens() async {
        let accounts = AppSettings.shared.accounts
        AppLogger.info("Validating tokens for \(accounts.count) accounts", log: AppLogger.auth)

        for account in accounts where account.isEnabled {
            _ = await validateAndRefreshToken(forAccount: account.email)
        }
    }

    /// Updates the auth status for an account
    func updateAccountAuthStatus(email: String, status: AuthStatus) {
        if var account = AppSettings.shared.account(forEmail: email) {
            if account.authStatus != status {
                account.authStatus = status
                if status != .valid {
                    account.lastAuthError = Date()
                }
                AppSettings.shared.updateAccount(account)
                AppLogger.privateInfo("Updated auth status for \(email) to \(status.rawValue)", log: AppLogger.auth)
            }
        }
    }
}
