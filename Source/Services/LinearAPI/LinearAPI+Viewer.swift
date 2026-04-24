import Foundation

extension LinearAPI {

    /// Fetches the current user + organization metadata. Called once after
    /// auth and on explicit refresh; never per-tab.
    func fetchViewer(accessToken: String, accountEmail: String? = nil) async throws -> Viewer {
        if TestDataProvider.isUITesting {
            return TestDataProvider.getViewer()
        }

        let query = """
        query FetchViewer {
          viewer {
            id
            name
            email
            organization {
              id
              name
              urlKey
              logoUrl
            }
          }
        }
        """

        struct Response: Decodable { let viewer: Viewer }

        let response: GraphQLResponse<Response> = try await execute(
            query: query,
            accessToken: accessToken,
            accountEmail: accountEmail
        )

        guard let data = response.data else { throw LinearError.invalidResponse }
        return data.viewer
    }

    /// Fetches the teams the viewer belongs to. Cached by `TeamsStore`; a
    /// workspace with 50+ teams is rare, and server-side pagination past
    /// that is unnecessary for the popover team picker.
    func fetchTeams(accessToken: String, accountEmail: String? = nil) async throws -> [Team] {
        if TestDataProvider.isUITesting {
            return TestDataProvider.getTeams()
        }

        let query = """
        query FetchTeams {
          viewer {
            teams(first: 50) {
              nodes {
                id
                name
                key
                icon
              }
            }
          }
        }
        """

        struct Response: Decodable {
            struct ViewerData: Decodable {
                struct TeamsData: Decodable { let nodes: [Team] }
                let teams: TeamsData
            }
            let viewer: ViewerData
        }

        let response: GraphQLResponse<Response> = try await execute(
            query: query,
            accessToken: accessToken,
            accountEmail: accountEmail
        )

        guard let data = response.data else { throw LinearError.invalidResponse }
        return data.viewer.teams.nodes
    }
}
