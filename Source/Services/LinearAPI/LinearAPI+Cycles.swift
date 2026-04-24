import Foundation

extension LinearAPI {

    /// Cap for the at-risk issue list inside an active cycle. Pulse only
    /// renders the worst offenders; 50 leaves headroom for sort + filter.
    private static let cycleIssuePageSize = 50

    /// Fetches the active cycle for a specific team plus the at-risk issues
    /// threatening it. Powers the Pulse tab.
    func fetchActiveCycleWithIssues(
        teamId: String,
        accessToken: String,
        accountEmail: String? = nil
    ) async throws -> ActiveCycleBundle {
        if TestDataProvider.isUITesting {
            return TestDataProvider.getActiveCycleBundle()
        }

        let query = """
        query FetchActiveCycle($teamId: String!, $first: Int!) {
          team(id: $teamId) {
            id
            name
            key
            activeCycle {
              id
              name
              number
              startsAt
              endsAt
              progress
              scopeHistory
              completedScopeHistory
              inProgressScopeHistory
              issues(first: $first) {
                nodes {
                  \(LinearGQL.cycleIssueFields)
                }
              }
            }
          }
        }
        """

        let variables: [String: Any] = [
            "teamId": teamId,
            "first": Self.cycleIssuePageSize
        ]

        struct Response: Decodable {
            struct TeamData: Decodable {
                let id: String
                let name: String
                let key: String
                let activeCycle: LinearCycle?
            }
            let team: TeamData
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

        return ActiveCycleBundle(
            teamId: data.team.id,
            teamName: data.team.name,
            teamKey: data.team.key,
            cycle: data.team.activeCycle
        )
    }
}

/// Bundle of team identity + its active cycle. `cycle` is nil when the team
/// doesn't have cycles enabled or has no cycle currently active.
struct ActiveCycleBundle {
    let teamId: String
    let teamName: String
    let teamKey: String
    let cycle: LinearCycle?
}
