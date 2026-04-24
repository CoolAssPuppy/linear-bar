import Foundation
import os.log

/// Service for interacting with Linear's GraphQL API
@MainActor
class LinearAPI {
    static let shared = LinearAPI()

    let endpoint = SafeExternalURL.mustParse("https://api.linear.app/graphql")
    let session: URLSession

    /// Shared decoder. Allocating a `JSONDecoder` per request showed up in
    /// profile traces once the popover tabs started fanning out multiple
    /// concurrent queries.
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    private static let rateLimitRetryableStatus = 429

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true
        session = URLSession(configuration: config)
    }

    // MARK: - GraphQL Execution

    func execute<T: Decodable>(
        query: String,
        variables: [String: Any]? = nil,
        accessToken: String,
        accountEmail: String? = nil,
        isRetry: Bool = false
    ) async throws -> GraphQLResponse<T> {
        try Task.checkCancellation()
        var currentAccessToken = accessToken

        if !isRetry, let email = accountEmail {
            if let freshToken = KeychainService.shared.retrieveAccessToken(forAccount: email) {
                currentAccessToken = freshToken
            }
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(currentAccessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any] = ["query": query]
        if let variables = variables {
            body["variables"] = variables
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        try Task.checkCancellation()

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LinearError.networkError(NSError(domain: "LinearAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"]))
        }

        if httpResponse.statusCode == 401 {
            if !isRetry, let email = accountEmail {
                AppLogger.info("Access token expired, attempting refresh", log: AppLogger.api)
                do {
                    let newAccessToken = try await LinearAuthService.shared.refreshAccessToken(forAccount: email)
                    AppLogger.info("Token refreshed successfully, retrying request", log: AppLogger.api)

                    if var account = AppSettings.shared.account(forEmail: email) {
                        if account.authStatus != .valid {
                            account.authStatus = .valid
                            AppSettings.shared.updateAccount(account)
                        }
                    }

                    return try await execute(
                        query: query,
                        variables: variables,
                        accessToken: newAccessToken,
                        accountEmail: email,
                        isRetry: true
                    )
                } catch {
                    AppLogger.error("Failed to refresh token", log: AppLogger.api, error: error)
                    throw LinearError.authenticationRequired
                }
            } else {
                throw LinearError.authenticationRequired
            }
        }

        if httpResponse.statusCode == Self.rateLimitRetryableStatus {
            if !isRetry,
               let retryAfter = Self.retryAfterDelay(from: httpResponse),
               retryAfter > 0 {
                AppLogger.info("Rate limited; retrying once after \(retryAfter)s", log: AppLogger.api)
                try await Task.sleep(nanoseconds: UInt64(retryAfter * 1_000_000_000))
                try Task.checkCancellation()
                return try await execute(
                    query: query,
                    variables: variables,
                    accessToken: currentAccessToken,
                    accountEmail: accountEmail,
                    isRetry: true
                )
            }
            throw LinearError.rateLimitExceeded
        }

        // Try to decode the body as a GraphQL envelope regardless of status
        // so schema errors surface as `.graphQLError(message)` instead of
        // opaque HTTP codes.
        if let decoded = try? decoder.decode(GraphQLResponse<T>.self, from: data) {
            if let errors = decoded.errors, !errors.isEmpty {
                let message = errors.map { $0.message }.joined(separator: ", ")
                AppLogger.privateError("GraphQL error: \(message)", log: AppLogger.api)
                throw LinearError.graphQLError(message)
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                throw LinearError.networkError(NSError(
                    domain: "LinearAPI",
                    code: httpResponse.statusCode,
                    userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode)"]
                ))
            }

            return decoded
        }

        // Body wasn't a GraphQL response at all — only log privately because
        // the raw body can include arbitrary content.
        if let body = String(data: data, encoding: .utf8) {
            AppLogger.privateError("Non-GraphQL response (status \(httpResponse.statusCode)): \(body)", log: AppLogger.api)
        }

        if (200...299).contains(httpResponse.statusCode) {
            throw LinearError.invalidResponse
        }

        throw LinearError.networkError(NSError(
            domain: "LinearAPI",
            code: httpResponse.statusCode,
            userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode)"]
        ))
    }

    static func retryAfterDelay(from response: HTTPURLResponse) -> TimeInterval? {
        guard let raw = response.value(forHTTPHeaderField: "Retry-After")?.trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty else {
            return nil
        }

        if let seconds = TimeInterval(raw), seconds >= 0 {
            return min(seconds, 15)
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "EEE',' dd MMM yyyy HH':'mm':'ss z"
        guard let date = formatter.date(from: raw) else { return nil }
        return min(max(0, date.timeIntervalSinceNow), 15)
    }
}

// MARK: - Error types

enum LinearError: LocalizedError {
    case networkError(Error)
    case authenticationRequired
    case rateLimitExceeded
    case invalidResponse
    case graphQLError(String)

    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .authenticationRequired:
            return "Authentication required. Please sign in again."
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please try again later."
        case .invalidResponse:
            return "Invalid response from Linear API."
        case .graphQLError(let message):
            return "Linear API error: \(message)"
        }
    }
}
