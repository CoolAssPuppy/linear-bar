import Foundation

extension LinearAPI {

    /// Fetches issues created by the current user
    func fetchMyIssues(accessToken: String, accountEmail: String? = nil) async throws -> [Issue] {
        if TestDataProvider.isUITesting {
            return TestDataProvider.getRecentIssues()
        }

        let query = """
        query {
          viewer {
            createdIssues(first: 100, orderBy: updatedAt) {
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
        }
        """

        struct Response: Decodable {
            struct ViewerData: Decodable {
                struct IssuesData: Decodable {
                    let nodes: [Issue]
                }
                let createdIssues: IssuesData
            }
            let viewer: ViewerData
        }

        let response: GraphQLResponse<Response> = try await execute(query: query, accessToken: accessToken, accountEmail: accountEmail)

        guard let data = response.data else {
            throw LinearError.invalidResponse
        }

        return data.viewer.createdIssues.nodes
    }

    /// Fetches issues assigned to the current user
    func fetchAssignedIssues(accessToken: String, accountEmail: String? = nil) async throws -> [Issue] {
        if TestDataProvider.isUITesting {
            return TestDataProvider.getRecentIssues()
        }

        let query = """
        query {
          viewer {
            assignedIssues(first: 100, orderBy: updatedAt) {
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
                team {
                  id
                  name
                  key
                }
                assignee {
                  name
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
        }
        """

        struct Response: Decodable {
            struct ViewerData: Decodable {
                struct IssuesData: Decodable {
                    let nodes: [Issue]
                }
                let assignedIssues: IssuesData
            }
            let viewer: ViewerData
        }

        let response: GraphQLResponse<Response> = try await execute(query: query, accessToken: accessToken, accountEmail: accountEmail)

        guard let data = response.data else {
            throw LinearError.invalidResponse
        }

        return data.viewer.assignedIssues.nodes
    }

    /// Fetches issues for a specific team
    func fetchTeamIssues(teamId: String, accessToken: String, accountEmail: String? = nil) async throws -> [Issue] {
        if TestDataProvider.isUITesting {
            return TestDataProvider.getRecentIssues()
        }

        let query = """
        query($teamId: String!) {
          team(id: $teamId) {
            issues(first: 100, orderBy: updatedAt) {
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
        }
        """

        let variables: [String: Any] = ["teamId": teamId]

        struct Response: Decodable {
            struct TeamData: Decodable {
                struct IssuesData: Decodable {
                    let nodes: [Issue]
                }
                let issues: IssuesData
            }
            let team: TeamData
        }

        let response: GraphQLResponse<Response> = try await execute(query: query, variables: variables, accessToken: accessToken, accountEmail: accountEmail)

        guard let data = response.data else {
            throw LinearError.invalidResponse
        }

        return data.team.issues.nodes
    }
}
