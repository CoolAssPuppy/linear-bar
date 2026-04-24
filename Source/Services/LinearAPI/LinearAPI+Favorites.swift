import Foundation

extension LinearAPI {

    /// Page size for the Faves tab. Favorites are user-curated and
    /// rarely run to hundreds of entries; 50 is generous.
    private static let favoritesPageSize = 50

    /// Fetches the viewer's favorites from Linear, surfacing issue and
    /// project targets. Other subtypes (document, cycle, custom view,
    /// label, roadmap, predefined view) decode with all targets nil and
    /// are filtered out at the view layer.
    func fetchFavorites(
        accessToken: String,
        accountEmail: String? = nil
    ) async throws -> [LinearFavorite] {
        if TestDataProvider.isUITesting {
            return TestDataProvider.getFavorites()
        }

        // Favorites live on Query, not on User/Viewer. An earlier draft of
        // this query nested them under `viewer { favorites }` and Linear
        // rejected it with "Cannot query field favorites on type User".
        let query = """
        query FetchFavorites($first: Int!) {
          favorites(first: $first, includeArchived: false) {
            nodes {
              id
              type
              folderName
              issue {
                id
                identifier
                title
                url
                state { name type }
                team { id name key }
              }
              project {
                id
                name
                url
                icon
                color
                state
                progress
              }
            }
          }
        }
        """

        let variables: [String: Any] = ["first": Self.favoritesPageSize]

        struct Response: Decodable {
            struct Conn: Decodable { let nodes: [LinearFavorite] }
            let favorites: Conn
        }

        let response: GraphQLResponse<Response> = try await execute(
            query: query,
            variables: variables,
            accessToken: accessToken,
            accountEmail: accountEmail
        )

        guard let data = response.data else { throw LinearError.invalidResponse }
        let nodes = data.favorites.nodes
        let issueCount = nodes.filter { $0.issue != nil }.count
        let projectCount = nodes.filter { $0.project != nil }.count
        let typeCounts = Dictionary(grouping: nodes, by: { $0.type }).mapValues { $0.count }
        AppLogger.info(
            "Faves fetch: \(nodes.count) favorites (issues=\(issueCount), projects=\(projectCount), byType=\(typeCounts))",
            log: AppLogger.api
        )
        return nodes
    }
}
