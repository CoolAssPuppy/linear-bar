import Foundation

extension LinearAPI {

    /// Fetches issues the viewer has touched recently — assigned, created,
    /// subscribed, or commented. Used by the Recent tab.
    ///
    /// Linear resolves the `since` duration (`"P2W"`, `"P1W"`, `"P1M"`)
    /// server-side via the `DateTimeOrDuration` scalar, so the filter stays
    /// cached across requests.
    func fetchTouchedIssues(
        accessToken: String,
        accountEmail: String? = nil,
        since: String = "P2W",
        limit: Int = 50
    ) async throws -> [Issue] {
        if TestDataProvider.isUITesting {
            return TestDataProvider.getRecentIssues()
        }

        let query = """
        query Recent($since: DateTimeOrDuration!, $first: Int!) {
          issues(
            first: $first
            orderBy: updatedAt
            filter: {
              updatedAt: { gt: $since }
              or: [
                { assignee: { isMe: { eq: true } } }
                { creator: { isMe: { eq: true } } }
                { subscribers: { some: { isMe: { eq: true } } } }
              ]
            }
          ) {
            nodes {
              id
              identifier
              title
              url
              createdAt
              updatedAt
              dueDate
              state { name type }
              priority
              priorityLabel
              assignee { name }
              team { id name key icon }
              project { id name icon }
            }
          }
        }
        """

        let variables: [String: Any] = [
            "since": since,
            "first": limit
        ]

        struct Response: Decodable {
            struct IssuesData: Decodable {
                let nodes: [Issue]
            }
            let issues: IssuesData
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
