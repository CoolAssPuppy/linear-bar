import Foundation

extension LinearAPI {

    /// Max page size for the popover's issue lists. 50 comfortably covers
    /// the visible rows (popover height fits ~10, with scroll); going
    /// higher is wasted bandwidth. Centralized so Mine / Recent / Team
    /// queries stay in sync.
    private static let issueListPageSize = 50

    /// Fetches issues created by the current user.
    func fetchMyIssues(accessToken: String, accountEmail: String? = nil) async throws -> [Issue] {
        if TestDataProvider.isUITesting {
            return TestDataProvider.getRecentIssues()
        }

        let query = """
        query FetchMyIssues($first: Int!) {
          viewer {
            createdIssues(first: $first, orderBy: updatedAt) {
              nodes {
                \(LinearGQL.issueCompactFields)
              }
            }
          }
        }
        """

        let variables: [String: Any] = ["first": Self.issueListPageSize]

        struct Response: Decodable {
            struct ViewerData: Decodable {
                struct IssuesData: Decodable { let nodes: [Issue] }
                let createdIssues: IssuesData
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
        return data.viewer.createdIssues.nodes
    }

    /// Fetches issues assigned to the current user.
    func fetchAssignedIssues(accessToken: String, accountEmail: String? = nil) async throws -> [Issue] {
        if TestDataProvider.isUITesting {
            return TestDataProvider.getRecentIssues()
        }

        let query = """
        query FetchAssignedIssues($first: Int!) {
          viewer {
            assignedIssues(first: $first, orderBy: updatedAt) {
              nodes {
                \(LinearGQL.issueCompactFields)
              }
            }
          }
        }
        """

        let variables: [String: Any] = ["first": Self.issueListPageSize]

        struct Response: Decodable {
            struct ViewerData: Decodable {
                struct IssuesData: Decodable { let nodes: [Issue] }
                let assignedIssues: IssuesData
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
        return data.viewer.assignedIssues.nodes
    }

    /// Fetches issues for a specific team.
    func fetchTeamIssues(teamId: String, accessToken: String, accountEmail: String? = nil) async throws -> [Issue] {
        if TestDataProvider.isUITesting {
            return TestDataProvider.getRecentIssues()
        }

        let query = """
        query FetchTeamIssues($teamId: String!, $first: Int!) {
          team(id: $teamId) {
            issues(first: $first, orderBy: updatedAt) {
              nodes {
                \(LinearGQL.issueCompactFields)
              }
            }
          }
        }
        """

        let variables: [String: Any] = [
            "teamId": teamId,
            "first": Self.issueListPageSize
        ]

        struct Response: Decodable {
            struct TeamData: Decodable {
                struct IssuesData: Decodable { let nodes: [Issue] }
                let issues: IssuesData
            }
            let team: TeamData
        }

        let response: GraphQLResponse<Response> = try await execute(
            query: query,
            variables: variables,
            accessToken: accessToken,
            accountEmail: accountEmail
        )

        guard let data = response.data else { throw LinearError.invalidResponse }
        return data.team.issues.nodes
    }
}
