import Foundation

extension LinearAPI {

    /// Fetches issues the viewer has touched recently — assigned plus created.
    /// Used by the Recent tab.
    ///
    /// Earlier attempts used a root `issues(filter: { or: [...] })` query to
    /// merge assignee / creator / subscribers on the server, but the filter
    /// shape rejected on at least one workspace tested. Issuing the two
    /// documented per-user connections (`viewer.assignedIssues`,
    /// `viewer.createdIssues`) and merging client-side is bulletproof and
    /// cheap enough (two parallel requests instead of one).
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
        query Recent($first: Int!) {
          viewer {
            assignedIssues(first: $first, orderBy: updatedAt) {
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
            createdIssues(first: $first, orderBy: updatedAt) {
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
        }
        """

        let variables: [String: Any] = ["first": min(limit, 50)]

        struct Response: Decodable {
            struct ViewerData: Decodable {
                struct Conn: Decodable { let nodes: [Issue] }
                let assignedIssues: Conn
                let createdIssues: Conn
            }
            let viewer: ViewerData
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

        // Merge, dedupe on id, keep the most recent version of each issue,
        // sort by updatedAt.
        var byId: [String: Issue] = [:]
        for issue in data.viewer.assignedIssues.nodes + data.viewer.createdIssues.nodes {
            byId[issue.id] = issue
        }

        return byId.values.sorted {
            ($0.updatedAt ?? .distantPast) > ($1.updatedAt ?? .distantPast)
        }
    }
}
