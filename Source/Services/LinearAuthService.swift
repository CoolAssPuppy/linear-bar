import Foundation
import AppKit
import AuthenticationServices
import Security
import os.log

/// Represents a pair of access and refresh tokens
struct TokenPair {
    let accessToken: String
    let refreshToken: String?
    let expiresIn: Int?
}

/// Service for handling OAuth authentication with Linear
@MainActor
class LinearAuthService: NSObject {
    static let shared = LinearAuthService()

    // MARK: - OAuth Configuration
    // Credentials are stored in LinearAuthSecrets.swift (gitignored)
    // Copy LinearAuthSecrets.swift.template to LinearAuthSecrets.swift and add your credentials
    let clientId = LinearAuthSecrets.clientId
    let clientSecret = LinearAuthSecrets.clientSecret
    let callbackURLScheme = "linearbar"
    let redirectURI = "linearbar://oauth/callback"
    private let authorizationURL = SafeExternalURL.mustParse("https://linear.app/oauth/authorize")
    let tokenURL = SafeExternalURL.mustParse("https://api.linear.app/oauth/token")

    private var authSession: ASWebAuthenticationSession?

    /// CSRF-defense state parameter for the in-flight OAuth flow.
    /// Generated fresh on every `authorize()` call and verified against
    /// the `state` returned in the callback URL. Main-actor isolated so
    /// there's no race between the callback handler reading it and a
    /// concurrent authorize() overwriting it.
    @MainActor private var pendingAuthState: String?

    private override init() {
        super.init()
    }

    // MARK: - Public Methods

    /// Generates a cryptographically-secure random OAuth state token.
    /// 32 bytes of entropy, base64url-encoded (no padding). Matches
    /// what `SecRandomCopyBytes` guarantees: CSPRNG-quality randomness.
    private static func generateOAuthState() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes)
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    /// Initiates the OAuth flow using ASWebAuthenticationSession
    @MainActor
    func authorize(completion: @escaping (Result<TokenPair, Error>) -> Void) {
        // Reentrance guard: if a sign-in is already in flight, cancel it
        // before starting a new one. Otherwise the two flows race for
        // `pendingAuthState` — whichever callback lands last will have
        // the mismatched state and fail verification, producing the
        // confusing "OAuth state verification failed" error after a
        // double-click on Add Account.
        if let existing = authSession {
            AppLogger.info("Cancelling in-flight OAuth session before starting a new one", log: AppLogger.auth)
            existing.cancel()
            authSession = nil
            pendingAuthState = nil
        }

        let state = Self.generateOAuthState()
        pendingAuthState = state

        guard var components = URLComponents(url: authorizationURL, resolvingAgainstBaseURL: false) else {
            completion(.failure(NSError(domain: "LinearAuthService", code: -1,
                                        userInfo: [NSLocalizedDescriptionKey: "Failed to construct authorization URL"])))
            return
        }
        components.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "scope", value: "read,write"),
            URLQueryItem(name: "state", value: state)
        ]

        guard let authURL = components.url else {
            completion(.failure(NSError(domain: "LinearAuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to construct authorization URL"])))
            return
        }

        AppLogger.info("Starting ASWebAuthenticationSession with redirect_uri: \(redirectURI)", log: AppLogger.auth)

        let session = ASWebAuthenticationSession(
            url: authURL,
            callbackURLScheme: callbackURLScheme
        ) { [weak self] callbackURL, error in
            Task { @MainActor in
                self?.handleAuthSessionCallback(callbackURL: callbackURL, error: error, completion: completion)
            }
        }

        session.presentationContextProvider = self
        session.prefersEphemeralWebBrowserSession = true

        self.authSession = session

        if !session.start() {
            AppLogger.error("Failed to start ASWebAuthenticationSession", log: AppLogger.auth)
            completion(.failure(NSError(domain: "LinearAuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to start authentication session"])))
        }
    }

    /// Handles the callback from ASWebAuthenticationSession
    private func handleAuthSessionCallback(
        callbackURL: URL?,
        error: Error?,
        completion: @escaping (Result<TokenPair, Error>) -> Void
    ) {
        self.authSession = nil

        if let error = error as? ASWebAuthenticationSessionError {
            switch error.code {
            case .canceledLogin:
                AppLogger.info("User canceled authentication", log: AppLogger.auth)
                completion(.failure(NSError(domain: "LinearAuthService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Authentication was canceled"])))
            case .presentationContextNotProvided:
                AppLogger.error("Presentation context not provided", log: AppLogger.auth)
                completion(.failure(error))
            case .presentationContextInvalid:
                AppLogger.error("Presentation context invalid", log: AppLogger.auth)
                completion(.failure(error))
            @unknown default:
                AppLogger.error("Unknown ASWebAuthenticationSession error: \(error)", log: AppLogger.auth)
                completion(.failure(error))
            }
            return
        }

        if let error = error {
            AppLogger.error("Authentication error: \(error.localizedDescription)", log: AppLogger.auth)
            completion(.failure(error))
            return
        }

        guard let callbackURL = callbackURL else {
            AppLogger.error("No callback URL received", log: AppLogger.auth)
            completion(.failure(NSError(domain: "LinearAuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No callback URL received"])))
            return
        }

        // Log only host + path — the query string carries `code=` and `state=`
        // which are sensitive.
        let sanitized = "\(callbackURL.scheme ?? "?")://\(callbackURL.host ?? "?")\(callbackURL.path)"
        AppLogger.debug("Received callback URL: \(sanitized)", log: AppLogger.auth)

        guard let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            completion(.failure(NSError(domain: "LinearAuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid callback URL"])))
            return
        }

        if let errorParam = queryItems.first(where: { $0.name == "error" })?.value {
            let errorDescription = queryItems.first(where: { $0.name == "error_description" })?.value ?? errorParam
            completion(.failure(NSError(domain: "LinearAuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: errorDescription])))
            return
        }

        guard let code = queryItems.first(where: { $0.name == "code" })?.value else {
            completion(.failure(NSError(domain: "LinearAuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No authorization code in callback"])))
            return
        }

        // CSRF defense: the callback must echo the exact `state` we sent
        // in the authorize() request. A missing or mismatched state means
        // the callback did not originate from our own authorize() call.
        let returnedState = queryItems.first(where: { $0.name == "state" })?.value
        let expected = pendingAuthState
        pendingAuthState = nil

        guard let expected = expected,
              let returnedState = returnedState,
              returnedState == expected else {
            AppLogger.error("OAuth state mismatch or missing; rejecting callback", log: AppLogger.auth)
            completion(.failure(NSError(domain: "LinearAuthService", code: -3, userInfo: [NSLocalizedDescriptionKey: "OAuth state verification failed"])))
            return
        }

        AppLogger.debug("Received authorization code: \(code.prefix(20))...", log: AppLogger.auth)

        Task {
            do {
                let tokenPair = try await exchangeCodeForToken(code: code)
                completion(.success(tokenPair))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Adds a new Linear account by initiating OAuth flow and storing credentials
    func addLinearAccount(completion: @escaping (Result<LinearAccount, Error>) -> Void) {
        authorize { result in
            Task { @MainActor in
                switch result {
                case .success(let tokenPair):
                    do {
                        let viewer = try await LinearAPI.shared.fetchViewer(accessToken: tokenPair.accessToken)
                        NSApp.activate(ignoringOtherApps: true)

                        let accessTokenSaved = KeychainService.shared.saveAccessToken(tokenPair.accessToken, forAccount: viewer.email)
                        guard accessTokenSaved else {
                            completion(.failure(NSError(domain: "LinearAuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to save access token to keychain"])))
                            return
                        }

                        if let refreshToken = tokenPair.refreshToken {
                            let refreshTokenSaved = KeychainService.shared.saveRefreshToken(refreshToken, forAccount: viewer.email)
                            if !refreshTokenSaved {
                                AppLogger.privateError("Failed to save refresh token to keychain for \(viewer.email)", log: AppLogger.auth)
                            } else {
                                AppLogger.privateInfo("Successfully saved refresh token for \(viewer.email)", log: AppLogger.auth)
                            }
                        } else {
                            AppLogger.info("No refresh token provided by Linear OAuth", log: AppLogger.auth)
                        }

                        if let expiresIn = tokenPair.expiresIn {
                            _ = KeychainService.shared.saveTokenExpiration(expiresIn, forAccount: viewer.email)
                            AppLogger.privateInfo("Token expires in \(expiresIn / 3600) hours for \(viewer.email)", log: AppLogger.auth)
                        }

                        var account = LinearAccount(
                            email: viewer.email,
                            name: viewer.name,
                            organizationSlug: viewer.organization?.urlKey,
                            organizationName: viewer.organization?.name,
                            organizationLogoUrl: viewer.organization?.logoUrl,
                            isEnabled: true
                        )

                        if let existing = AppSettings.shared.account(forEmail: viewer.email) {
                            account.color = existing.color
                            AppSettings.shared.updateAccount(account)
                        } else {
                            account.color = self.generateDefaultColor()
                            AppSettings.shared.addAccount(account)
                        }

                        AppLogger.privateInfo("Successfully authenticated and saved credentials for \(viewer.email)", log: AppLogger.auth)
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

    // MARK: - Private Helpers

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
