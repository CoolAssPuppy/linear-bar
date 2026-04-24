import Foundation

extension LinearAPI {

    /// Searches for issues across the workspace
    func searchIssues(term: String, accessToken: String, accountEmail: String? = nil) async throws -> [Issue] {
        if TestDataProvider.isUITesting {
            return TestDataProvider.searchIssues(term: term)
        }
        let query = """
        query($term: String!) {
          searchIssues(term: $term, first: 50, includeArchived: false) {
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
        """

        let variables: [String: Any] = ["term": term]

        struct Response: Decodable {
            struct SearchData: Decodable {
                let nodes: [Issue]
            }
            let searchIssues: SearchData
        }

        let response: GraphQLResponse<Response> = try await execute(query: query, variables: variables, accessToken: accessToken, accountEmail: accountEmail)

        guard let data = response.data else {
            throw LinearError.invalidResponse
        }

        return data.searchIssues.nodes
    }

    /// Searches for projects across the workspace
    func searchProjects(term: String, accessToken: String, accountEmail: String? = nil) async throws -> [Project] {
        if TestDataProvider.isUITesting {
            return TestDataProvider.searchProjects(term: term)
        }
        let query = """
        query($term: String!) {
          searchProjects(term: $term, first: 50) {
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

        let variables: [String: Any] = ["term": term]

        struct Response: Decodable {
            struct SearchData: Decodable {
                let nodes: [Project]
            }
            let searchProjects: SearchData
        }

        let response: GraphQLResponse<Response> = try await execute(query: query, variables: variables, accessToken: accessToken, accountEmail: accountEmail)

        guard let data = response.data else {
            throw LinearError.invalidResponse
        }

        return data.searchProjects.nodes
    }

    /// Searches workspace initiatives by name / description.
    func searchInitiatives(term: String, accessToken: String, accountEmail: String? = nil) async throws -> [Initiative] {
        if TestDataProvider.isUITesting {
            return TestDataProvider.searchInitiatives(term: term)
        }
        let query = """
        query($term: String!) {
          initiatives(first: 50, filter: { name: { containsIgnoreCase: $term } }) {
            nodes {
              id
              name
              description
              url
              createdAt
              updatedAt
              icon
              status
              targetDate
            }
          }
        }
        """

        let variables: [String: Any] = ["term": term]

        struct Response: Decodable {
            struct Conn: Decodable { let nodes: [Initiative] }
            let initiatives: Conn
        }

        let response: GraphQLResponse<Response> = try await execute(query: query, variables: variables, accessToken: accessToken, accountEmail: accountEmail)

        guard let data = response.data else { throw LinearError.invalidResponse }
        return data.initiatives.nodes
    }
}
