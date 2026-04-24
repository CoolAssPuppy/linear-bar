import Foundation

extension LinearAPI {

    /// Max page size for search results. 30 is enough to fill the popover
    /// without overfetching from the expensive `searchIssues` root.
    private static let searchPageSize = 30

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
            "first": Self.searchPageSize
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
            "first": Self.searchPageSize
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
            "first": Self.searchPageSize
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
