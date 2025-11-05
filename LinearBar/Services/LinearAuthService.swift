import Foundation
import AppKit

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

    private var authCompletion: ((Result<String, Error>) -> Void)?

    private init() {}

    // MARK: - Public Methods

    /// Initiates the OAuth flow by opening the authorization URL in the user's browser
    func authorize(completion: @escaping (Result<String, Error>) -> Void) {
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

        print("[LinearAuth] Opening authorization URL with redirect_uri: \(redirectURI)")

        // Open the authorization URL in the default browser
        NSWorkspace.shared.open(url)
    }

    /// Handles the OAuth callback URL after user authorization
    func handleCallback(url: URL) -> Bool {
        print("[LinearAuth] Received callback URL: \(url.absoluteString)")

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

        print("[LinearAuth] Received authorization code: \(code.prefix(20))...")

        // Exchange code for access token
        Task {
            do {
                let accessToken = try await exchangeCodeForToken(code: code)
                authCompletion?(.success(accessToken))
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
                case .success(let accessToken):
                    do {
                        // Fetch user information
                        let viewer = try await LinearAPI.shared.fetchViewer(accessToken: accessToken)

                        // Ensure app is active so keychain permission dialog can appear
                        NSApp.activate(ignoringOtherApps: true)

                        // Save access token to keychain
                        let tokenSaved = KeychainService.shared.saveAccessToken(accessToken, forAccount: viewer.email)

                        guard tokenSaved else {
                            completion(.failure(NSError(domain: "LinearAuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to save credentials to keychain"])))
                            return
                        }

                        // Create or update account
                        var account = LinearAccount(
                            email: viewer.email,
                            name: viewer.name,
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

                        print("[LinearAuth] Successfully authenticated and saved credentials for \(viewer.email)")
                        completion(.success(account))

                    } catch {
                        print("[LinearAuth] Error fetching user information: \(error)")
                        completion(.failure(error))
                    }

                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }

    // MARK: - Private Methods

    private func exchangeCodeForToken(code: String) async throws -> String {
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

        print("[LinearAuth] Exchanging code for token...")
        print("[LinearAuth] Client ID: \(clientId.prefix(10))...")
        print("[LinearAuth] Redirect URI: \(redirectURI)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "LinearAuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response from server"])
        }

        print("[LinearAuth] Response status code: \(httpResponse.statusCode)")

        guard (200...299).contains(httpResponse.statusCode) else {
            // Try to parse error response
            var errorMessage = "Failed to exchange code for token (HTTP \(httpResponse.statusCode))"
            if let errorBody = String(data: data, encoding: .utf8) {
                print("[LinearAuth] Error response: \(errorBody)")

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
        }

        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
        print("[LinearAuth] Successfully received access token")
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
