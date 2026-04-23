import Foundation
import os.log

/// Service for interacting with Linear's GraphQL API
@MainActor
class LinearAPI {
    static let shared = LinearAPI()

    let endpoint = URL(string: "https://api.linear.app/graphql")!
    let session: URLSession

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

        if httpResponse.statusCode == 429 {
            throw LinearError.rateLimitExceeded
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorBody = String(data: data, encoding: .utf8) {
                AppLogger.privateError("HTTP \(httpResponse.statusCode) error response: \(errorBody)", log: AppLogger.api)
            }
            throw LinearError.networkError(NSError(domain: "LinearAPI", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode)"]))
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let graphQLResponse = try decoder.decode(GraphQLResponse<T>.self, from: data)

            if let errors = graphQLResponse.errors, !errors.isEmpty {
                let errorMessage = errors.map { $0.message }.joined(separator: ", ")
                throw LinearError.graphQLError(errorMessage)
            }

            return graphQLResponse
        } catch let error as LinearError {
            throw error
        } catch {
            AppLogger.error("Decoding error", log: AppLogger.api, error: error)
            throw LinearError.invalidResponse
        }
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
