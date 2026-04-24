import Foundation

extension LinearAPI {

    /// Page sizes scoped per connection. SearchView renders at most 7
    /// issues, 2 projects, 2 initiatives (`combined.prefix(12)`). Over-
    /// fetching on every keystroke is pure waste — and `searchIssues` is
    /// one of Linear's more expensive roots. These values leave comfort-
    /// able headroom for the Show-completed/canceled filter to drop rows
    /// without starving the result list.
    private static let searchIssuesPageSize = 15
    private static let searchProjectsPageSize = 5
    private static let searchInitiativesPageSize = 5

    /// Searches for issues across the workspace.
    func searchIssues(term: String, accessToken: String, accountEmail: String? = nil) async throws -> [Issue] {
        if TestDataProvider.isUITesting {
            return TestDataProvider.searchIssues(term: term)
        }

        let query = """
        query SearchIssues($term: String!, $first: Int!) {
          searchIssues(term: $term, first: $first, includeArchived: false) {
            nodes {
              \(LinearGQL.issueCompactFields)
            }
          }
        }
        """

        let variables: [String: Any] = [
            "term": term,
            "first": Self.searchIssuesPageSize
        ]

        struct Response: Decodable {
            struct SearchData: Decodable { let nodes: [Issue] }
            let searchIssues: SearchData
        }

        let response: GraphQLResponse<Response> = try await execute(
            query: query,
            variables: variables,
            accessToken: accessToken,
            accountEmail: accountEmail
        )

        guard let data = response.data else { throw LinearError.invalidResponse }
        return data.searchIssues.nodes
    }

    /// Searches for projects across the workspace.
    func searchProjects(term: String, accessToken: String, accountEmail: String? = nil) async throws -> [Project] {
        if TestDataProvider.isUITesting {
            return TestDataProvider.searchProjects(term: term)
        }

        let query = """
        query SearchProjects($term: String!, $first: Int!) {
          searchProjects(term: $term, first: $first) {
            nodes {
              \(LinearGQL.projectFields)
            }
          }
        }
        """

        let variables: [String: Any] = [
            "term": term,
            "first": Self.searchProjectsPageSize
        ]

        struct Response: Decodable {
            struct SearchData: Decodable { let nodes: [Project] }
            let searchProjects: SearchData
        }

        let response: GraphQLResponse<Response> = try await execute(
            query: query,
            variables: variables,
            accessToken: accessToken,
            accountEmail: accountEmail
        )

        guard let data = response.data else { throw LinearError.invalidResponse }
        return data.searchProjects.nodes
    }

    /// Searches workspace initiatives by name.
    func searchInitiatives(term: String, accessToken: String, accountEmail: String? = nil) async throws -> [Initiative] {
        if TestDataProvider.isUITesting {
            return TestDataProvider.searchInitiatives(term: term)
        }

        let query = """
        query SearchInitiatives($term: String!, $first: Int!) {
          initiatives(first: $first, filter: { name: { containsIgnoreCase: $term } }) {
            nodes {
              \(LinearGQL.initiativeFields)
            }
          }
        }
        """

        let variables: [String: Any] = [
            "term": term,
            "first": Self.searchInitiativesPageSize
        ]

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
