import Foundation

extension LinearAPI {

    /// Fetches the active cycle for a specific team plus the at-risk issues
    /// threatening it. Powers the Pulse tab. "At risk" means any non-done,
    /// non-canceled issue assigned to the current cycle — the client then
    /// ranks them by risk signal (SLA, unassigned, stale, blocked) for display.
    func fetchActiveCycleWithIssues(
        teamId: String,
        accessToken: String,
        accountEmail: String? = nil
    ) async throws -> ActiveCycleBundle {
        if TestDataProvider.isUITesting {
            return TestDataProvider.getActiveCycleBundle()
        }

        let query = """
        query ActiveCycle($teamId: String!) {
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
              issues(first: 100, filter: { state: { type: { nin: ["completed", "canceled"] } } }) {
                nodes {
                  id
                  identifier
                  title
                  url
                  updatedAt
                  dueDate
                  priority
                  priorityLabel
                  state {
                    name
                    type
                  }
                  assignee {
                    name
                  }
                  slaBreachesAt
                }
              }
            }
          }
        }
        """

        let variables: [String: Any] = ["teamId": teamId]

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

/// The complete Pulse payload for a single team: team identity plus either
/// its active cycle (with embedded issues) or nil if the team has no active
/// cycle configured.
struct ActiveCycleBundle {
    let teamId: String
    let teamName: String
    let teamKey: String
    let cycle: LinearCycle?
}
