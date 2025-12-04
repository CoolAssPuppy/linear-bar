import Foundation
import AppKit
import os.log

/// Represents a pair of access and refresh tokens
struct TokenPair {
    let accessToken: String
    let refreshToken: String?
    let expiresIn: Int?
}

/// Service for handling OAuth authentication with Linear
@MainActor
class LinearAuthService {
    static let shared = LinearAuthService()

    // MARK: - OAuth Configuration
    // Credentials are stored in LinearAuthSecrets.swift (gitignored)
    // Copy LinearAuthSecrets.swift.template to LinearAuthSecrets.swift and add your credentials
    private let clientId = LinearAuthSecrets.clientId
    private let clientSecret = LinearAuthSecrets.clientSecret
    private let redirectURI = "linearbar://oauth/callback"
    private let authorizationURL = "https://linear.app/oauth/authorize"
    private let tokenURL = "https://api.linear.app/oauth/token"

    private var authCompletion: ((Result<TokenPair, Error>) -> Void)?

    private init() {}

    // MARK: - Public Methods

    /// Initiates the OAuth flow by opening the authorization URL in the user's browser
    func authorize(completion: @escaping (Result<TokenPair, Error>) -> Void) {
        self.authCompletion = completion

        var components = URLComponents(string: authorizationURL)!
        components.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "scope", value: "read,write")
        ]

        guard let url = components.url else {
            completion(.failure(NSError(domain: "LinearAuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to construct authorization URL"])))
            return
        }

        AppLogger.info("Opening authorization URL with redirect_uri: \(redirectURI)", log: AppLogger.auth)

        // Open the authorization URL in the default browser
        NSWorkspace.shared.open(url)
    }

    /// Handles the OAuth callback URL after user authorization
    func handleCallback(url: URL) -> Bool {
        AppLogger.debug("Received callback URL: \(url.absoluteString)", log: AppLogger.auth)

        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            authCompletion?(.failure(NSError(domain: "LinearAuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid callback URL"])))
            authCompletion = nil
            return false
        }

        // Check for error in callback
        if let error = queryItems.first(where: { $0.name == "error" })?.value {
            let errorDescription = queryItems.first(where: { $0.name == "error_description" })?.value ?? error
            authCompletion?(.failure(NSError(domain: "LinearAuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: errorDescription])))
            authCompletion = nil
            return false
        }

        // Extract authorization code
        guard let code = queryItems.first(where: { $0.name == "code" })?.value else {
            authCompletion?(.failure(NSError(domain: "LinearAuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No authorization code in callback"])))
            authCompletion = nil
            return false
        }

        AppLogger.debug("Received authorization code: \(code.prefix(20))...", log: AppLogger.auth)

        // Exchange code for access token
        Task {
            do {
                let tokenPair = try await exchangeCodeForToken(code: code)
                authCompletion?(.success(tokenPair))
                authCompletion = nil
            } catch {
                authCompletion?(.failure(error))
                authCompletion = nil
            }
        }

        return true
    }

    /// Adds a new Linear account by initiating OAuth flow and storing credentials
    func addLinearAccount(completion: @escaping (Result<LinearAccount, Error>) -> Void) {
        authorize { result in
            Task { @MainActor in
                switch result {
                case .success(let tokenPair):
                    do {
                        // Fetch user information
                        let viewer = try await LinearAPI.shared.fetchViewer(accessToken: tokenPair.accessToken)

                        // Ensure app is active so keychain permission dialog can appear
                        NSApp.activate(ignoringOtherApps: true)

                        // Save access token to keychain
                        let accessTokenSaved = KeychainService.shared.saveAccessToken(tokenPair.accessToken, forAccount: viewer.email)

                        guard accessTokenSaved else {
                            completion(.failure(NSError(domain: "LinearAuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to save access token to keychain"])))
                            return
                        }

                        // Save refresh token to keychain if available
                        if let refreshToken = tokenPair.refreshToken {
                            let refreshTokenSaved = KeychainService.shared.saveRefreshToken(refreshToken, forAccount: viewer.email)
                            if !refreshTokenSaved {
                                AppLogger.error("Failed to save refresh token to keychain for \(viewer.email)", log: AppLogger.auth)
                            } else {
                                AppLogger.info("Successfully saved refresh token for \(viewer.email)", log: AppLogger.auth)
                            }
                        } else {
                            AppLogger.info("No refresh token provided by Linear OAuth", log: AppLogger.auth)
                        }

                        // Create or update account
                        var account = LinearAccount(
                            email: viewer.email,
                            name: viewer.name,
                            organizationSlug: viewer.organization?.urlKey,
                            isEnabled: true
                        )

                        // If account already exists, preserve existing settings
                        if let existing = AppSettings.shared.account(forEmail: viewer.email) {
                            account.color = existing.color
                            AppSettings.shared.updateAccount(account)
                        } else {
                            // Assign a default color for new account
                            account.color = self.generateDefaultColor()
                            AppSettings.shared.addAccount(account)
                        }

                        AppLogger.info("Successfully authenticated and saved credentials for \(viewer.email)", log: AppLogger.auth)
                        completion(.success(account))

                    } catch {
                        AppLogger.error("Error fetching user information", log: AppLogger.auth, error: error)
                        completion(.failure(error))
                    }

                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }

    // MARK: - Private Methods

    private func exchangeCodeForToken(code: String) async throws -> TokenPair {
        var request = URLRequest(url: URL(string: tokenURL)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        // Build URL-encoded form data
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "grant_type", value: "authorization_code"),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "client_secret", value: clientSecret)
        ]

        // Get the query string and convert to data
        guard let query = components.percentEncodedQuery else {
            throw NSError(domain: "LinearAuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode request body"])
        }

        request.httpBody = query.data(using: .utf8)

        AppLogger.info("Exchanging code for token...", log: AppLogger.auth)
        AppLogger.debug("Client ID: \(clientId.prefix(10))...", log: AppLogger.auth)
        AppLogger.debug("Redirect URI: \(redirectURI)", log: AppLogger.auth)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "LinearAuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response from server"])
        }

        AppLogger.debug("Response status code: \(httpResponse.statusCode)", log: AppLogger.auth)

        guard (200...299).contains(httpResponse.statusCode) else {
            // Try to parse error response
            var errorMessage = "Failed to exchange code for token (HTTP \(httpResponse.statusCode))"
            if let errorBody = String(data: data, encoding: .utf8) {
                AppLogger.error("Error response: \(errorBody)", log: AppLogger.auth)

                // Try to parse Linear's error format
                if let jsonObject = try? JSONSerialization.jsonObject(with: data),
                   let errorData = jsonObject as? [String: Any] {
                    if let error = errorData["error"] as? String {
                        errorMessage = error
                    }
                    if let errorDescription = errorData["error_description"] as? String {
                        errorMessage = errorDescription
                    }
                } else {
                    errorMessage += ": \(errorBody)"
                }
            }
            throw NSError(domain: "LinearAuthService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }

        struct TokenResponse: Decodable {
            let access_token: String
            let refresh_token: String?
            let expires_in: Int?
        }

        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
        AppLogger.info("Successfully received access token", log: AppLogger.auth)
        if tokenResponse.refresh_token != nil {
            AppLogger.info("Refresh token also received", log: AppLogger.auth)
        }

        return TokenPair(
            accessToken: tokenResponse.access_token,
            refreshToken: tokenResponse.refresh_token,
            expiresIn: tokenResponse.expires_in
        )
    }

    /// Validates and proactively refreshes the access token for an account if needed
    /// Returns true if the account has valid credentials, false if re-authentication is required
    func validateAndRefreshToken(forAccount email: String) async -> Bool {
        AppLogger.info("Validating token for \(email)", log: AppLogger.auth)

        // Check if we have an access token
        guard let accessToken = KeychainService.shared.retrieveAccessToken(forAccount: email) else {
            AppLogger.error("No access token found for \(email)", log: AppLogger.auth)
            updateAccountAuthStatus(email: email, status: .needsAuth)
            return false
        }

        // Try to make a simple API call to validate the token
        do {
            _ = try await LinearAPI.shared.fetchViewer(accessToken: accessToken, accountEmail: email)
            AppLogger.info("Token is valid for \(email)", log: AppLogger.auth)
            updateAccountAuthStatus(email: email, status: .valid)
            return true
        } catch LinearError.authenticationRequired {
            // Token refresh was attempted but failed
            AppLogger.error("Token validation failed for \(email) - authentication required", log: AppLogger.auth)
            updateAccountAuthStatus(email: email, status: .expired)
            return false
        } catch {
            // Other errors (network, etc.) - don't mark as expired
            AppLogger.error("Token validation error for \(email): \(error.localizedDescription)", log: AppLogger.auth)
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
    private func updateAccountAuthStatus(email: String, status: AuthStatus) {
        if var account = AppSettings.shared.account(forEmail: email) {
            if account.authStatus != status {
                account.authStatus = status
                if status != .valid {
                    account.lastAuthError = Date()
                }
                AppSettings.shared.updateAccount(account)
                AppLogger.info("Updated auth status for \(email) to \(status.rawValue)", log: AppLogger.auth)
            }
        }
    }

    /// Refreshes an access token using a refresh token
    func refreshAccessToken(forAccount email: String) async throws -> String {
        // Retrieve refresh token from keychain
        guard let refreshToken = KeychainService.shared.retrieveRefreshToken(forAccount: email) else {
            AppLogger.error("No refresh token found for \(email)", log: AppLogger.auth)
            updateAccountAuthStatus(email: email, status: .expired)
            throw NSError(domain: "LinearAuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No refresh token available"])
        }

        var request = URLRequest(url: URL(string: tokenURL)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        // Build URL-encoded form data
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "grant_type", value: "refresh_token"),
            URLQueryItem(name: "refresh_token", value: refreshToken),
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "client_secret", value: clientSecret)
        ]

        guard let query = components.percentEncodedQuery else {
            throw NSError(domain: "LinearAuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode request body"])
        }

        request.httpBody = query.data(using: .utf8)

        AppLogger.info("Refreshing access token for \(email)...", log: AppLogger.auth)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "LinearAuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response from server"])
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            var errorMessage = "Failed to refresh token (HTTP \(httpResponse.statusCode))"
            if let errorBody = String(data: data, encoding: .utf8) {
                AppLogger.error("Error response: \(errorBody)", log: AppLogger.auth)

                if let jsonObject = try? JSONSerialization.jsonObject(with: data),
                   let errorData = jsonObject as? [String: Any] {
                    if let error = errorData["error"] as? String {
                        errorMessage = error
                    }
                    if let errorDescription = errorData["error_description"] as? String {
                        errorMessage = errorDescription
                    }
                } else {
                    errorMessage += ": \(errorBody)"
                }
            }

            // If refresh token is invalid or expired, delete it and update auth status
            if httpResponse.statusCode == 401 || httpResponse.statusCode == 400 {
                AppLogger.error("Refresh token is invalid or expired for \(email)", log: AppLogger.auth)
                _ = KeychainService.shared.deleteRefreshToken(forAccount: email)
                _ = KeychainService.shared.deleteAccessToken(forAccount: email)
                updateAccountAuthStatus(email: email, status: .expired)
            }

            throw NSError(domain: "LinearAuthService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }

        struct TokenResponse: Decodable {
            let access_token: String
            let refresh_token: String?
            let expires_in: Int?
        }

        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
        AppLogger.info("Successfully refreshed access token for \(email)", log: AppLogger.auth)

        // Save the new access token
        let accessTokenSaved = KeychainService.shared.saveAccessToken(tokenResponse.access_token, forAccount: email)
        guard accessTokenSaved else {
            throw NSError(domain: "LinearAuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to save refreshed access token"])
        }

        // Save the new refresh token if provided
        if let newRefreshToken = tokenResponse.refresh_token {
            let refreshTokenSaved = KeychainService.shared.saveRefreshToken(newRefreshToken, forAccount: email)
            if refreshTokenSaved {
                AppLogger.info("Successfully saved new refresh token for \(email)", log: AppLogger.auth)
            } else {
                AppLogger.error("Failed to save new refresh token for \(email)", log: AppLogger.auth)
            }
        }

        return tokenResponse.access_token
    }

    private func generateDefaultColor() -> String {
        let colors = [
            "#5E6AD2", // Linear purple
            "#10B981", // green
            "#F59E0B", // orange
            "#EF4444", // red
            "#3B82F6", // blue
            "#8B5CF6", // purple
            "#EC4899", // pink
            "#14B8A6"  // teal
        ]
        return colors.randomElement() ?? "#5E6AD2"
    }
}
