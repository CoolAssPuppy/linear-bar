import Foundation

extension LinearAuthService {
    enum OAuthFlowContext {
        case refresh
        case exchange

        var label: String {
            switch self {
            case .refresh: return "OAuth refresh"
            case .exchange: return "Token exchange"
            }
        }

        var defaultErrorMessage: String {
            switch self {
            case .refresh: return "Failed to refresh token"
            case .exchange: return "Failed to exchange code for token"
            }
        }
    }

    struct OAuthTokenResponse: Decodable {
        let access_token: String
        let refresh_token: String?
        let expires_in: Int?
    }


    /// Exchanges an authorization code for an access token
    func exchangeCodeForToken(code: String) async throws -> TokenPair {
        let request = buildTokenRequest(grantType: "authorization_code", extraParams: [
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "redirect_uri", value: redirectURI)
        ])

        AppLogger.info("Exchanging code for token...", log: AppLogger.auth)
        AppLogger.debug("Client ID: \(clientId.prefix(10))...", log: AppLogger.auth)
        AppLogger.debug("Redirect URI: \(redirectURI)", log: AppLogger.auth)

        return try await executeTokenRequest(request)
    }

    /// Refreshes an access token using a refresh token
    func refreshAccessToken(forAccount email: String) async throws -> String {
        guard let refreshToken = KeychainService.shared.retrieveRefreshToken(forAccount: email) else {
            AppLogger.privateError("No refresh token found for \(email)", log: AppLogger.auth)
            updateAccountAuthStatus(email: email, status: .expired)
            throw NSError(domain: "LinearAuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No refresh token available"])
        }

        let request = buildTokenRequest(grantType: "refresh_token", extraParams: [
            URLQueryItem(name: "refresh_token", value: refreshToken)
        ])

        AppLogger.privateInfo("Refreshing access token for \(email)...", log: AppLogger.auth)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "LinearAuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response from server"])
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let parsed = Self.parseOAuthError(data: data, statusCode: httpResponse.statusCode, context: .refresh)
            AppLogger.privateError(parsed.logMessage, log: AppLogger.auth)

            if httpResponse.statusCode == 401 || httpResponse.statusCode == 400 {
                AppLogger.privateError("Refresh token is invalid or expired for \(email)", log: AppLogger.auth)
                _ = KeychainService.shared.deleteRefreshToken(forAccount: email)
                _ = KeychainService.shared.deleteAccessToken(forAccount: email)
                updateAccountAuthStatus(email: email, status: .expired)
            }

            throw NSError(domain: "LinearAuthService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: parsed.userMessage])
        }

        let tokenResponse = try JSONDecoder().decode(OAuthTokenResponse.self, from: data)
        AppLogger.privateInfo("Successfully refreshed access token for \(email)", log: AppLogger.auth)

        let accessTokenSaved = KeychainService.shared.saveAccessToken(tokenResponse.access_token, forAccount: email)
        guard accessTokenSaved else {
            throw NSError(domain: "LinearAuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to save refreshed access token"])
        }

        if let newRefreshToken = tokenResponse.refresh_token {
            let refreshTokenSaved = KeychainService.shared.saveRefreshToken(newRefreshToken, forAccount: email)
            if refreshTokenSaved {
                AppLogger.privateInfo("Successfully saved new refresh token for \(email)", log: AppLogger.auth)
            } else {
                AppLogger.privateError("Failed to save new refresh token for \(email)", log: AppLogger.auth)
            }
        }

        if let expiresIn = tokenResponse.expires_in {
            _ = KeychainService.shared.saveTokenExpiration(expiresIn, forAccount: email)
            AppLogger.privateInfo("New token expires in \(expiresIn / 3600) hours for \(email)", log: AppLogger.auth)
        }

        return tokenResponse.access_token
    }

    // MARK: - Shared helpers

    /// Builds a URL-encoded token request with common parameters
    func buildTokenRequest(grantType: String, extraParams: [URLQueryItem]) -> URLRequest {
        var request = URLRequest(url: URL(string: tokenURL)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "grant_type", value: grantType),
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "client_secret", value: clientSecret)
        ] + extraParams

        request.httpBody = components.percentEncodedQuery?.data(using: .utf8)
        return request
    }

    /// Executes a token request and parses the response into a TokenPair
    func executeTokenRequest(_ request: URLRequest) async throws -> TokenPair {
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "LinearAuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response from server"])
        }

        AppLogger.debug("Response status code: \(httpResponse.statusCode)", log: AppLogger.auth)

        guard (200...299).contains(httpResponse.statusCode) else {
            let parsed = Self.parseOAuthError(data: data, statusCode: httpResponse.statusCode, context: .exchange)
            AppLogger.privateError(parsed.logMessage, log: AppLogger.auth)
            throw NSError(domain: "LinearAuthService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: parsed.userMessage])
        }

        let tokenResponse = try JSONDecoder().decode(OAuthTokenResponse.self, from: data)
        AppLogger.info("Successfully received access token", log: AppLogger.auth)
        if tokenResponse.refresh_token != nil {
            AppLogger.info("Refresh token also received", log: AppLogger.auth)
        }
        if let expiresIn = tokenResponse.expires_in {
            AppLogger.info("Token expires in \(expiresIn) seconds (\(expiresIn / 3600) hours)", log: AppLogger.auth)
        }

        return TokenPair(
            accessToken: tokenResponse.access_token,
            refreshToken: tokenResponse.refresh_token,
            expiresIn: tokenResponse.expires_in
        )
    }

    static func parseOAuthError(data: Data, statusCode: Int, context: OAuthFlowContext) -> (userMessage: String, logMessage: String) {
        let fallback = "\(context.defaultErrorMessage) (HTTP \(statusCode))"

        guard let jsonObject = try? JSONSerialization.jsonObject(with: data),
              let errorData = jsonObject as? [String: Any] else {
            return (
                userMessage: fallback,
                logMessage: "\(context.label) failed (HTTP \(statusCode), non-JSON body)"
            )
        }

        let oauthError = errorData["error"] as? String
        let oauthDescription = errorData["error_description"] as? String
        let userMessage = oauthDescription ?? oauthError ?? fallback
        return (
            userMessage: userMessage,
            logMessage: "\(context.label) failed: \(oauthError ?? "unknown") - \(oauthDescription ?? "")"
        )
    }
}
