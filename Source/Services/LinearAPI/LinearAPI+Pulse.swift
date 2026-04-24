import Foundation

extension LinearAPI {

    /// Page size for each Pulse connection. 30 from each keeps the
    /// merged feed roughly one-two days deep on active workspaces
    /// without overfetching.
    private static let pulsePageSize = 30

    /// Scope filter applied to the Pulse feed.
    enum PulseScope: String, CaseIterable, Identifiable {
        /// Every update across the workspace.
        case workspace
        /// Updates on projects that belong to a team the viewer is on.
        /// Initiative updates are hidden (initiatives aren't team-scoped).
        case teams
        /// Updates the viewer authored. Server-filtered via
        /// `user.isMe.eq = true`.
        case mine

        public var id: String { rawValue }
    }

    /// Fetches the viewer's workspace Pulse feed — a merged stream of
    /// project status updates and initiative updates, ordered newest
    /// first. Mirrors what Linear shows on its web Pulse page.
    ///
    /// Scope controls which subset of updates comes back:
    /// - `.workspace`: everything.
    /// - `.mine`: server-filtered to the viewer's own updates on both
    ///   connections.
    /// - `.teams`: workspace-wide fetch, then client-filtered to
    ///   project updates whose project belongs to any team in
    ///   `viewerTeamIds`; initiative updates are dropped.
    ///
    /// The two connections are fetched in parallel and merged
    /// client-side. A failure on one side (e.g. schema drift on
    /// initiativeUpdates) is swallowed so the feed still renders from
    /// the surviving connection.
    func fetchPulseUpdates(
        accessToken: String,
        accountEmail: String? = nil,
        scope: PulseScope = .workspace,
        viewerTeamIds: Set<String> = []
    ) async throws -> [LinearPulseUpdate] {
        if TestDataProvider.isUITesting {
            return TestDataProvider.getPulseUpdates()
        }

        async let projects = fetchProjectUpdates(
            accessToken: accessToken,
            accountEmail: accountEmail,
            onlyMine: scope == .mine
        )
        async let initiatives = scope == .teams
            ? [] as [LinearPulseUpdate]
            : fetchInitiativeUpdates(
                accessToken: accessToken,
                accountEmail: accountEmail,
                onlyMine: scope == .mine
            )

        var projectResults = (try? await projects) ?? []
        let initiativeResults = (try? await initiatives) ?? []

        if scope == .teams, !viewerTeamIds.isEmpty {
            projectResults = projectResults.filter { update in
                guard let nodes = update.project?.teams?.nodes else { return false }
                return nodes.contains { viewerTeamIds.contains($0.id) }
            }
        }

        return (projectResults + initiativeResults).sorted {
            ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast)
        }
    }

    // MARK: - Per-endpoint fetches

    private func fetchProjectUpdates(
        accessToken: String,
        accountEmail: String?,
        onlyMine: Bool
    ) async throws -> [LinearPulseUpdate] {
        let filterArg = onlyMine
            ? ", filter: { user: { isMe: { eq: true } } }"
            : ""
        let query = """
        query FetchProjectUpdates($first: Int!) {
          projectUpdates(first: $first\(filterArg)) {
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
                teams { nodes { id } }
              }
            }
          }
        }
        """

        let variables: [String: Any] = ["first": Self.pulsePageSize]

        struct Response: Decodable {
            struct Conn: Decodable { let nodes: [LinearPulseUpdate] }
            let projectUpdates: Conn
        }

        let response: GraphQLResponse<Response> = try await execute(
            query: query,
            variables: variables,
            accessToken: accessToken,
            accountEmail: accountEmail
        )

        guard let data = response.data else { throw LinearError.invalidResponse }
        return data.projectUpdates.nodes
    }

    private func fetchInitiativeUpdates(
        accessToken: String,
        accountEmail: String?,
        onlyMine: Bool
    ) async throws -> [LinearPulseUpdate] {
        let filterArg = onlyMine
            ? ", filter: { user: { isMe: { eq: true } } }"
            : ""
        let query = """
        query FetchInitiativeUpdates($first: Int!) {
          initiativeUpdates(first: $first\(filterArg)) {
            nodes {
              id
              body
              createdAt
              user {
                id
                name
                displayName
                avatarUrl
              }
              initiative {
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
            struct Conn: Decodable { let nodes: [LinearPulseUpdate] }
            let initiativeUpdates: Conn
        }

        let response: GraphQLResponse<Response> = try await execute(
            query: query,
            variables: variables,
            accessToken: accessToken,
            accountEmail: accountEmail
        )

        guard let data = response.data else { throw LinearError.invalidResponse }
        return data.initiativeUpdates.nodes
    }
}
