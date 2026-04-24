import Foundation

extension LinearAPI {

    /// Max page size for the popover's issue lists. 50 comfortably covers
    /// the visible rows (popover height fits ~10, with scroll); going
    /// higher is wasted bandwidth. Centralized so Mine / Recent queries
    /// stay in sync.
    private static let issueListPageSize = 50

    /// Bundle of the viewer's assigned and created issues, fetched in a
    /// single GraphQL operation. Mine's Show chip (Assigned / Created /
    /// All) pivots over these two lists without re-fetching.
    struct MineIssuesBundle {
        let assigned: [Issue]
        let created: [Issue]
    }

    /// Fetches the viewer's assigned + created issues in one round trip.
    /// Replaces the earlier pair of `fetchAssignedIssues` +
    /// `fetchMyIssues` calls — same payload shape, half the HTTP traffic
    /// and auth-refresh risk per Mine refresh.
    func fetchMineIssues(accessToken: String, accountEmail: String? = nil) async throws -> MineIssuesBundle {
        if TestDataProvider.isUITesting {
            let fixtures = TestDataProvider.getRecentIssues()
            return MineIssuesBundle(assigned: fixtures, created: fixtures)
        }

        let query = """
        query FetchMineIssues($first: Int!) {
          viewer {
            assignedIssues(first: $first, orderBy: updatedAt) {
              nodes { \(LinearGQL.issueCompactFields) }
            }
            createdIssues(first: $first, orderBy: updatedAt) {
              nodes { \(LinearGQL.issueCompactFields) }
            }
          }
        }
        """

        let variables: [String: Any] = ["first": Self.issueListPageSize]

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

        guard let data = response.data else { throw LinearError.invalidResponse }
        return MineIssuesBundle(
            assigned: data.viewer.assignedIssues.nodes,
            created: data.viewer.createdIssues.nodes
        )
    }
}
