import Foundation

extension LinearAPI {

    /// Page size for the Pulse tab. 40 is enough for a day or two of
    /// activity on a busy workspace without overfetching.
    private static let pulsePageSize = 40

    /// Fetches the viewer's workspace Pulse feed — a stream of project
    /// status updates, ordered newest first. Mirrors what Linear shows
    /// on its web Pulse page. Initiative updates may be added in a
    /// future pass; for now this is project updates only because they
    /// make up the bulk of real-world Pulse traffic.
    func fetchPulseUpdates(
        accessToken: String,
        accountEmail: String? = nil
    ) async throws -> [LinearProjectUpdate] {
        if TestDataProvider.isUITesting {
            return TestDataProvider.getPulseUpdates()
        }

        let query = """
        query FetchPulse($first: Int!) {
          projectUpdates(first: $first) {
            nodes {
              id
              body
              createdAt
              health
              user {
                id
                name
                displayName
                avatarUrl
              }
              project {
                id
                name
                url
                color
                icon
              }
            }
          }
        }
        """

        let variables: [String: Any] = ["first": Self.pulsePageSize]

        struct Response: Decodable {
            struct Conn: Decodable { let nodes: [LinearProjectUpdate] }
            let projectUpdates: Conn
        }

        let response: GraphQLResponse<Response> = try await execute(
            query: query,
            variables: variables,
            accessToken: accessToken,
            accountEmail: accountEmail
        )

        guard let data = response.data else { throw LinearError.invalidResponse }
        return data.projectUpdates.nodes.sorted {
            ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast)
        }
    }
}
