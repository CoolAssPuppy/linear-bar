import Foundation

extension LinearAPI {

    /// Fetches projects for the current user
    func fetchMyProjects(accessToken: String, accountEmail: String? = nil) async throws -> [Project] {
        if TestDataProvider.isUITesting {
            return TestDataProvider.getProjects()
        }

        // First get the current user's ID
        let viewerQuery = """
        query {
          viewer {
            id
          }
        }
        """

        struct ViewerResponse: Decodable {
            let viewer: ViewerInfo
        }
        struct ViewerInfo: Decodable {
            let id: String
        }

        let viewerResult: GraphQLResponse<ViewerResponse> = try await execute(query: viewerQuery, accessToken: accessToken, accountEmail: accountEmail)
        guard let viewerId = viewerResult.data?.viewer.id else {
            throw LinearError.invalidResponse
        }

        let query = """
        query {
          projects(first: 100, orderBy: updatedAt, filter: { lead: { id: { eq: "\(viewerId)" } } }) {
            nodes {
              id
              name
              description
              url
              createdAt
              updatedAt
              state
              progress
              icon
              lead {
                name
              }
            }
          }
        }
        """

        struct Response: Decodable {
            struct ProjectsData: Decodable {
                let nodes: [Project]
            }
            let projects: ProjectsData
        }

        let response: GraphQLResponse<Response> = try await execute(query: query, accessToken: accessToken, accountEmail: accountEmail)

        guard let data = response.data else {
            throw LinearError.invalidResponse
        }

        return data.projects.nodes
    }

    /// Fetches projects assigned to the current user (as lead or member)
    func fetchAssignedProjects(accessToken: String, accountEmail: String? = nil) async throws -> [Project] {
        return try await fetchMyProjects(accessToken: accessToken, accountEmail: accountEmail)
    }

    /// Fetches initiatives in the workspace
    func fetchInitiatives(accessToken: String, accountEmail: String? = nil) async throws -> [Initiative] {
        if TestDataProvider.isUITesting {
            return TestDataProvider.getInitiatives()
        }

        let query = """
        query {
          initiatives(first: 100, orderBy: updatedAt) {
            nodes {
              id
              name
              description
              url
              createdAt
              updatedAt
              icon
              status
            }
          }
        }
        """

        struct Response: Decodable {
            struct InitiativesData: Decodable {
                let nodes: [Initiative]
            }
            let initiatives: InitiativesData
        }

        let response: GraphQLResponse<Response> = try await execute(query: query, accessToken: accessToken, accountEmail: accountEmail)

        guard let data = response.data else {
            throw LinearError.invalidResponse
        }

        return data.initiatives.nodes
    }
}
