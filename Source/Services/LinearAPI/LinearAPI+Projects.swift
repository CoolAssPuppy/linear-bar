import Foundation

extension LinearAPI {

    /// Fetches the projects the viewer can see in the current workspace,
    /// sorted by most-recently-updated. Filtering to "projects I lead" or
    /// "projects I'm a member of" requires the or/and filter shape that has
    /// 400'd in real workspaces, so we stay simple and fetch what the
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
        query RecentProjects($first: Int!) {
          projects(first: $first, orderBy: updatedAt) {
            nodes {
              id
              name
              description
              url
              createdAt
              updatedAt
              state
              progress
              icon
              lead { name }
              targetDate
            }
          }
        }
        """

        let variables: [String: Any] = ["first": limit]

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

        guard let data = response.data else {
            throw LinearError.invalidResponse
        }

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
        query RecentInitiatives($first: Int!) {
          initiatives(first: $first, orderBy: updatedAt) {
            nodes {
              id
              name
              description
              url
              createdAt
              updatedAt
              icon
              status
              targetDate
            }
          }
        }
        """

        let variables: [String: Any] = ["first": limit]

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

        guard let data = response.data else {
            throw LinearError.invalidResponse
        }

        return data.initiatives.nodes
    }
}
