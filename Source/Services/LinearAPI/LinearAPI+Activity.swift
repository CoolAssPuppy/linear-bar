import Foundation

extension LinearAPI {

    /// Fetches issues the viewer has touched recently — assigned to, created,
    /// subscribed to, or commented on. Used by the Recent tab. The `since`
    /// argument accepts an ISO 8601 duration (`"P1W"`, `"P1D"`) which Linear
    /// resolves server-side; keeping the window tight keeps the query cheap.
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
                { comments: { some: { user: { isMe: { eq: true } } } } }
              ]
            }
          ) {
            nodes {
              id
              identifier
              title
              description
              url
              createdAt
              updatedAt
              dueDate
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
              labels {
                nodes {
                  id
                  name
                  color
                }
              }
              project {
                id
                name
                icon
              }
              parent {
                id
                identifier
                title
              }
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
