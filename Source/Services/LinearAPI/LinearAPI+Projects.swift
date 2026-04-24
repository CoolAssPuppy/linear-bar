import Foundation

extension LinearAPI {

    /// Max page size for the Recent tab's project/initiative lists.
    private static let recentPageSize = 30

    /// Fetches the projects the viewer can see in the current workspace,
    /// sorted by most-recently-updated. Filtering to "projects I lead" or
    /// "projects I'm a member of" requires the or/and filter shape that
    /// has 400'd in real workspaces, so we stay simple and fetch what the
    /// viewer can see — the Recent tab then shows whatever is actually
    /// moving in the org.
    func fetchRecentProjects(
        accessToken: String,
        accountEmail: String? = nil,
        limit: Int = 30
    ) async throws -> [Project] {
        if TestDataProvider.isUITesting {
            return TestDataProvider.getRecentProjects()
        }

        let query = """
        query FetchRecentProjects($first: Int!) {
          projects(first: $first, orderBy: updatedAt) {
            nodes {
              \(LinearGQL.projectFields)
            }
          }
        }
        """

        let variables: [String: Any] = ["first": min(limit, Self.recentPageSize)]

        struct Response: Decodable {
            struct Conn: Decodable { let nodes: [Project] }
            let projects: Conn
        }

        let response: GraphQLResponse<Response> = try await execute(
            query: query,
            variables: variables,
            accessToken: accessToken,
            accountEmail: accountEmail
        )

        guard let data = response.data else { throw LinearError.invalidResponse }
        return data.projects.nodes
    }

    /// Fetches workspace initiatives sorted by most-recently-updated. Same
    /// rationale as projects — the workspace-wide view is cheap and the
    /// Recent tab surfaces whatever has moved.
    func fetchRecentInitiatives(
        accessToken: String,
        accountEmail: String? = nil,
        limit: Int = 30
    ) async throws -> [Initiative] {
        if TestDataProvider.isUITesting {
            return TestDataProvider.getRecentInitiatives()
        }

        let query = """
        query FetchRecentInitiatives($first: Int!) {
          initiatives(first: $first, orderBy: updatedAt) {
            nodes {
              \(LinearGQL.initiativeFields)
            }
          }
        }
        """

        let variables: [String: Any] = ["first": min(limit, Self.recentPageSize)]

        struct Response: Decodable {
            struct Conn: Decodable { let nodes: [Initiative] }
            let initiatives: Conn
        }

        let response: GraphQLResponse<Response> = try await execute(
            query: query,
            variables: variables,
            accessToken: accessToken,
            accountEmail: accountEmail
        )

        guard let data = response.data else { throw LinearError.invalidResponse }
        return data.initiatives.nodes
    }
}
