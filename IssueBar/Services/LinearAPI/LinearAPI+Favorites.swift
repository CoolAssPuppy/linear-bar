import Foundation

extension LinearAPI {

    struct FavoritesResponseData: Decodable {
        struct FavoritesConnection: Decodable {
            let nodes: [Favorite]
        }
        let favorites: FavoritesConnection
    }

    /// Fetches user's favorite items (issues, projects, initiatives)
    func fetchFavorites(accessToken: String, accountEmail: String? = nil) async throws -> [Favorite] {
        if TestDataProvider.isUITesting {
            return TestDataProvider.getFavorites()
        }

        let favoritesQuery = """
        query {
          favorites(first: 50) {
            nodes {
              id
              type
              sortOrder
              folderName
              parent {
                id
              }
              children {
                nodes {
                  id
                }
              }
              issue {
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
              project {
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
                targetDate
              }
              initiative {
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
              cycle {
                id
                name
                startsAt
                endsAt
              }
              label {
                id
                name
                color
              }
              customView {
                id
                name
                icon
              }
            }
          }
        }
        """

        let response: GraphQLResponse<FavoritesResponseData> = try await execute(query: favoritesQuery, accessToken: accessToken, accountEmail: accountEmail)

        guard let data = response.data else {
            AppLogger.error("No data in favorites response", log: AppLogger.api)
            if let errors = response.errors {
                AppLogger.error("GraphQL errors: \(errors)", log: AppLogger.api)
                return try await fetchAssignedIssuesAsFavorites(accessToken: accessToken, accountEmail: accountEmail)
            }
            throw LinearError.invalidResponse
        }

        return data.favorites.nodes
    }

    /// Fallback: Fetch assigned issues as favorites
    func fetchAssignedIssuesAsFavorites(accessToken: String, accountEmail: String? = nil) async throws -> [Favorite] {
        let query = """
        query {
          viewer {
            assignedIssues(first: 20, orderBy: updatedAt) {
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

        return data.viewer.assignedIssues.nodes.enumerated().map { index, issue in
            Favorite(
                id: "favorite-issue-\(issue.id)",
                type: "issue",
                sortOrder: Double(index),
                folderName: nil,
                issue: issue,
                project: nil,
                initiative: nil,
                customView: nil,
                cycle: nil,
                label: nil,
                parent: nil,
                children: nil
            )
        }
    }
}
