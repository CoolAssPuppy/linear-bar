import Foundation
import os.log

/// Service for interacting with Linear's GraphQL API
@MainActor
class LinearAPI {
    static let shared = LinearAPI()

    private let endpoint = URL(string: "https://api.linear.app/graphql")!
    private let session = URLSession.shared

    private init() {}

    // MARK: - Public API Methods

    /// Fetches the current user's information
    func fetchViewer(accessToken: String) async throws -> Viewer {
        let query = """
        query {
          viewer {
            id
            name
            email
          }
        }
        """

        struct Response: Decodable {
            let viewer: Viewer
        }

        let response: GraphQLResponse<Response> = try await execute(query: query, accessToken: accessToken)

        guard let data = response.data else {
            throw LinearError.invalidResponse
        }

        return data.viewer
    }

    /// Fetches user's favorite items (issues, projects, initiatives)
    func fetchFavorites(accessToken: String) async throws -> [Favorite] {
        AppLogger.debug("Fetching favorites...", log: AppLogger.api)
        // Try the favorites query at root level based on Linear SDK schema
        let favoritesQuery = """
        query {
          favorites(first: 50) {
            nodes {
              id
              type
              sortOrder
              folderName
              parent {
                id
              }
              children {
                nodes {
                  id
                }
              }
              issue {
                id
                identifier
                title
                url
                createdAt
                updatedAt
                state {
                  name
                  type
                }
                priority
                priorityLabel
                assignee {
                  name
                }
                team {
                  id
                  name
                  key
                }
              }
              project {
                id
                name
                url
                createdAt
                updatedAt
                state
                progress
                icon
                lead {
                  name
                }
              }
              initiative {
                id
                name
                url
                createdAt
                updatedAt
                icon
                status
              }
              cycle {
                id
                name
                startsAt
                endsAt
              }
              label {
                id
                name
                color
              }
              customView {
                id
                name
                icon
              }
            }
          }
        }
        """

        let response: GraphQLResponse<FavoritesResponseData> = try await execute(query: favoritesQuery, accessToken: accessToken)

        guard let data = response.data else {
            AppLogger.error("No data in favorites response", log: AppLogger.api)
            if let errors = response.errors {
                AppLogger.error("GraphQL errors: \(errors)", log: AppLogger.api)
                // Fall back to assigned issues if favorites query fails
                return try await fetchAssignedIssuesAsFavorites(accessToken: accessToken)
            }
            throw LinearError.invalidResponse
        }

        AppLogger.info("Successfully fetched \(data.favorites.nodes.count) favorites", log: AppLogger.api)

        // Debug: Log what types of favorites we got
        for favorite in data.favorites.nodes {
            var itemType = "unknown"
            if favorite.issue != nil {
                itemType = "issue"
            } else if favorite.project != nil {
                itemType = "project"
            } else if favorite.initiative != nil {
                itemType = "initiative"
            } else if favorite.customView != nil {
                itemType = "customView"
            } else if favorite.cycle != nil {
                itemType = "cycle"
            } else if favorite.label != nil {
                itemType = "label"
            } else if favorite.folderName != nil {
                itemType = "folder"
            }
            AppLogger.debug("Favorite: type=\(favorite.type ?? "nil"), itemType=\(itemType), folderName=\(favorite.folderName ?? "nil")", log: AppLogger.api)
        }

        return data.favorites.nodes
    }

    /// Fallback: Fetch assigned issues as favorites
    private func fetchAssignedIssuesAsFavorites(accessToken: String) async throws -> [Favorite] {
        AppLogger.info("Falling back to assigned issues for favorites", log: AppLogger.api)
        let query = """
        query {
          viewer {
            assignedIssues(first: 20, orderBy: updatedAt) {
              nodes {
                id
                identifier
                title
                url
                createdAt
                updatedAt
                state {
                  name
                  type
                }
                priority
                priorityLabel
                assignee {
                  name
                }
                team {
                  id
                  name
                  key
                }
              }
            }
          }
        }
        """

        struct Response: Decodable {
            struct ViewerData: Decodable {
                struct IssuesData: Decodable {
                    let nodes: [Issue]
                }
                let assignedIssues: IssuesData
            }
            let viewer: ViewerData
        }

        let response: GraphQLResponse<Response> = try await execute(query: query, accessToken: accessToken)

        guard let data = response.data else {
            throw LinearError.invalidResponse
        }

        return data.viewer.assignedIssues.nodes.enumerated().map { index, issue in
            Favorite(
                id: "favorite-issue-\(issue.id)",
                type: "issue",
                sortOrder: Double(index),
                folderName: nil,
                issue: issue,
                project: nil,
                initiative: nil,
                customView: nil,
                cycle: nil,
                label: nil,
                parent: nil,
                children: nil
            )
        }
    }

    struct FavoritesResponseData: Decodable {
        struct FavoritesConnection: Decodable {
            let nodes: [Favorite]
        }
        let favorites: FavoritesConnection
    }

    /// Fetches user's teams
    func fetchTeams(accessToken: String) async throws -> [Team] {
        let query = """
        query {
          viewer {
            teams(first: 50) {
              nodes {
                id
                name
                key
                icon
              }
            }
          }
        }
        """

        struct Response: Decodable {
            struct ViewerData: Decodable {
                struct TeamsData: Decodable {
                    let nodes: [Team]
                }
                let teams: TeamsData
            }
            let viewer: ViewerData
        }

        let response: GraphQLResponse<Response> = try await execute(query: query, accessToken: accessToken)

        guard let data = response.data else {
            throw LinearError.invalidResponse
        }

        return data.viewer.teams.nodes
    }

    /// Fetches issues created by the current user
    func fetchMyIssues(accessToken: String) async throws -> [Issue] {
        let query = """
        query {
          viewer {
            createdIssues(first: 100, orderBy: updatedAt) {
              nodes {
                id
                identifier
                title
                url
                createdAt
                updatedAt
                state {
                  name
                  type
                }
                priority
                priorityLabel
                team {
                  id
                  name
                  key
                }
              }
            }
          }
        }
        """

        struct Response: Decodable {
            struct ViewerData: Decodable {
                struct IssuesData: Decodable {
                    let nodes: [Issue]
                }
                let createdIssues: IssuesData
            }
            let viewer: ViewerData
        }

        let response: GraphQLResponse<Response> = try await execute(query: query, accessToken: accessToken)

        guard let data = response.data else {
            throw LinearError.invalidResponse
        }

        return data.viewer.createdIssues.nodes
    }

    /// Fetches issues assigned to the current user
    func fetchAssignedIssues(accessToken: String) async throws -> [Issue] {
        let query = """
        query {
          viewer {
            assignedIssues(first: 100, orderBy: updatedAt) {
              nodes {
                id
                identifier
                title
                url
                createdAt
                updatedAt
                state {
                  name
                  type
                }
                priority
                priorityLabel
                team {
                  id
                  name
                  key
                }
                assignee {
                  name
                }
              }
            }
          }
        }
        """

        struct Response: Decodable {
            struct ViewerData: Decodable {
                struct IssuesData: Decodable {
                    let nodes: [Issue]
                }
                let assignedIssues: IssuesData
            }
            let viewer: ViewerData
        }

        let response: GraphQLResponse<Response> = try await execute(query: query, accessToken: accessToken)

        guard let data = response.data else {
            throw LinearError.invalidResponse
        }

        return data.viewer.assignedIssues.nodes
    }

    /// Fetches issues for a specific team
    func fetchTeamIssues(teamId: String, accessToken: String) async throws -> [Issue] {
        let query = """
        query($teamId: String!) {
          team(id: $teamId) {
            issues(first: 100, orderBy: updatedAt) {
              nodes {
                id
                identifier
                title
                url
                createdAt
                updatedAt
                state {
                  name
                  type
                }
                priority
                priorityLabel
                assignee {
                  name
                }
              }
            }
          }
        }
        """

        let variables: [String: Any] = ["teamId": teamId]

        struct Response: Decodable {
            struct TeamData: Decodable {
                struct IssuesData: Decodable {
                    let nodes: [Issue]
                }
                let issues: IssuesData
            }
            let team: TeamData
        }

        let response: GraphQLResponse<Response> = try await execute(query: query, variables: variables, accessToken: accessToken)

        guard let data = response.data else {
            throw LinearError.invalidResponse
        }

        return data.team.issues.nodes
    }

    /// Fetches projects for the current user
    func fetchMyProjects(accessToken: String) async throws -> [Project] {
        // First get the current user's ID
        let viewerQuery = """
        query {
          viewer {
            id
          }
        }
        """

        struct ViewerResponse: Decodable {
            let viewer: ViewerInfo
        }
        struct ViewerInfo: Decodable {
            let id: String
        }

        let viewerResult: GraphQLResponse<ViewerResponse> = try await execute(query: viewerQuery, accessToken: accessToken)
        guard let viewerId = viewerResult.data?.viewer.id else {
            throw LinearError.invalidResponse
        }

        // Now fetch projects where the user is the creator or lead
        let query = """
        query {
          projects(first: 100, orderBy: updatedAt, filter: { lead: { id: { eq: "\(viewerId)" } } }) {
            nodes {
              id
              name
              url
              createdAt
              updatedAt
              state
              progress
              icon
              lead {
                name
              }
            }
          }
        }
        """

        struct Response: Decodable {
            struct ProjectsData: Decodable {
                let nodes: [Project]
            }
            let projects: ProjectsData
        }

        let response: GraphQLResponse<Response> = try await execute(query: query, accessToken: accessToken)

        guard let data = response.data else {
            throw LinearError.invalidResponse
        }

        return data.projects.nodes
    }

    /// Fetches projects assigned to the current user (as lead or member)
    func fetchAssignedProjects(accessToken: String) async throws -> [Project] {
        // Linear doesn't have a separate assignedProjects query, so we use the same projects query
        return try await fetchMyProjects(accessToken: accessToken)
    }

    /// Fetches initiatives in the workspace
    func fetchInitiatives(accessToken: String) async throws -> [Initiative] {
        let query = """
        query {
          initiatives(first: 100, orderBy: updatedAt) {
            nodes {
              id
              name
              url
              createdAt
              updatedAt
              icon
              status
            }
          }
        }
        """

        struct Response: Decodable {
            struct InitiativesData: Decodable {
                let nodes: [Initiative]
            }
            let initiatives: InitiativesData
        }

        let response: GraphQLResponse<Response> = try await execute(query: query, accessToken: accessToken)

        guard let data = response.data else {
            throw LinearError.invalidResponse
        }

        return data.initiatives.nodes
    }

    /// Searches for issues across the workspace
    func searchIssues(term: String, accessToken: String) async throws -> [Issue] {
        let query = """
        query($term: String!) {
          searchIssues(term: $term, first: 50, includeArchived: false) {
            nodes {
              id
              identifier
              title
              url
              createdAt
              updatedAt
              state {
                name
                type
              }
              priority
              priorityLabel
              team {
                id
                name
                key
              }
              assignee {
                name
              }
            }
          }
        }
        """

        let variables: [String: Any] = ["term": term]

        struct Response: Decodable {
            struct SearchData: Decodable {
                let nodes: [Issue]
            }
            let searchIssues: SearchData
        }

        let response: GraphQLResponse<Response> = try await execute(query: query, variables: variables, accessToken: accessToken)

        guard let data = response.data else {
            throw LinearError.invalidResponse
        }

        return data.searchIssues.nodes
    }

    /// Searches for projects across the workspace
    func searchProjects(term: String, accessToken: String) async throws -> [Project] {
        let query = """
        query($term: String!) {
          searchProjects(term: $term, first: 50) {
            nodes {
              id
              name
              url
              createdAt
              updatedAt
              state
              progress
              icon
              lead {
                name
              }
            }
          }
        }
        """

        let variables: [String: Any] = ["term": term]

        struct Response: Decodable {
            struct SearchData: Decodable {
                let nodes: [Project]
            }
            let searchProjects: SearchData
        }

        let response: GraphQLResponse<Response> = try await execute(query: query, variables: variables, accessToken: accessToken)

        guard let data = response.data else {
            throw LinearError.invalidResponse
        }

        return data.searchProjects.nodes
    }

    // MARK: - Private Methods

    private func execute<T: Decodable>(
        query: String,
        variables: [String: Any]? = nil,
        accessToken: String
    ) async throws -> GraphQLResponse<T> {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
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

        // Handle authentication errors
        if httpResponse.statusCode == 401 {
            throw LinearError.authenticationRequired
        }

        // Handle rate limiting
        if httpResponse.statusCode == 429 {
            throw LinearError.rateLimitExceeded
        }

        // Check for successful status code
        guard (200...299).contains(httpResponse.statusCode) else {
            // Try to parse error response
            if let errorBody = String(data: data, encoding: .utf8) {
                AppLogger.error("HTTP \(httpResponse.statusCode) error response: \(errorBody)", log: AppLogger.api)
            }
            throw LinearError.networkError(NSError(domain: "LinearAPI", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode)"]))
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let graphQLResponse = try decoder.decode(GraphQLResponse<T>.self, from: data)

            // Check for GraphQL errors
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

// MARK: - Error Types

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
