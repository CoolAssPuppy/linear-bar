import Foundation

extension LinearAPI {

    /// Fetches the issues most recently updated in the current workspace.
    /// The result is independent of assignment, creation, and subscription.
    func fetchRecentlyUpdatedIssues(
        accessToken: String,
        accountEmail: String? = nil,
        limit: Int = 50
    ) async throws -> [Issue] {
        if TestDataProvider.isUITesting {
            return TestDataProvider.getRecentIssues()
        }

        let query = """
        query FetchRecentlyUpdatedIssues($first: Int!) {
          issues(first: $first, orderBy: updatedAt) {
            nodes { \(LinearGQL.issueCompactFields) }
          }
        }
        """

        let variables: [String: Any] = ["first": min(limit, 50)]

        struct Response: Decodable {
            struct Connection: Decodable {
                let nodes: [Issue]
            }

            let issues: Connection
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
        return data.issues.nodes
    }
}
