import Foundation

extension LinearAPI {

    /// Per-connection page size. The Pulse window dropdown scales the
    /// request: wider windows fan out more rows so a 90-day view on a
    /// busy workspace doesn't silently truncate at 30 results.
    private static func pulsePageSize(for windowDays: Int) -> Int {
        switch windowDays {
        case ...7:  return 30
        case ...14: return 40
        case ...30: return 60
        default:    return 80
        }
    }

    /// ISO8601 formatter with fractional seconds disabled — Linear's
    /// GraphQL `DateTimeComparator` accepts either form but fractional
    /// seconds have been the more finicky format historically.
    private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private static func windowStartIso(daysAgo: Int) -> String {
        let date = Calendar(identifier: .gregorian).date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
        return isoFormatter.string(from: date)
    }

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
    /// - `.teams`: workspace-wide fetch, client-filtered to project
    ///   updates whose project belongs to any team in
    ///   `viewerTeamIds`, **union** with the viewer's own updates
    ///   (project + initiative). "My Teams" is a superset of "Just
    ///   Mine" in the user's mental model — authoring an update on a
    ///   project that isn't mapped to any of your teams in the
    ///   response still counts.
    ///
    /// Connections fetch in parallel. A failure on any side is
    /// swallowed so the feed still renders from the survivors.
    func fetchPulseUpdates(
        accessToken: String,
        accountEmail: String? = nil,
        scope: PulseScope = .workspace,
        viewerTeamIds: Set<String> = [],
        windowDays: Int = 14
    ) async throws -> [LinearPulseUpdate] {
        if TestDataProvider.isUITesting {
            return TestDataProvider.getPulseUpdates()
        }

        async let projectsAll = fetchProjectUpdates(
            accessToken: accessToken,
            accountEmail: accountEmail,
            onlyMine: scope == .mine,
            windowDays: windowDays
        )
        async let initiativesAll = scope == .teams
            ? [] as [LinearPulseUpdate]
            : fetchInitiativeUpdates(
                accessToken: accessToken,
                accountEmail: accountEmail,
                onlyMine: scope == .mine,
                windowDays: windowDays
            )

        // "My Teams" also needs my own authored updates (project +
        // initiative). Kick those off in parallel too so the wall-clock
        // cost is the single slowest request.
        async let myProjects = scope == .teams
            ? fetchProjectUpdates(
                accessToken: accessToken,
                accountEmail: accountEmail,
                onlyMine: true,
                windowDays: windowDays
            )
            : [] as [LinearPulseUpdate]
        async let myInitiatives = scope == .teams
            ? fetchInitiativeUpdates(
                accessToken: accessToken,
                accountEmail: accountEmail,
                onlyMine: true,
                windowDays: windowDays
            )
            : [] as [LinearPulseUpdate]

        // Project updates are the primary surface — let auth / rate-limit
        // failures propagate so PulseView can show the right sign-in or
        // back-off state instead of an empty-feed panel. Secondary
        // connections (initiatives, my-own team supplementary fetches)
        // stay best-effort so a perm error on one side doesn't empty the
        // whole feed.
        var projectResults: [LinearPulseUpdate]
        do {
            projectResults = try await projectsAll
        } catch LinearError.authenticationRequired {
            throw LinearError.authenticationRequired
        } catch LinearError.rateLimitExceeded {
            throw LinearError.rateLimitExceeded
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            projectResults = []
        }
        var initiativeResults = (try? await initiativesAll) ?? []
        let ownProjects = (try? await myProjects) ?? []
        let ownInitiatives = (try? await myInitiatives) ?? []

        if scope == .teams {
            // Keep updates whose project belongs to one of my teams.
            let teamFiltered = viewerTeamIds.isEmpty
                ? []
                : projectResults.filter { update in
                    guard let nodes = update.project?.teams?.nodes else { return false }
                    return nodes.contains { viewerTeamIds.contains($0.id) }
                }
            projectResults = Self.mergedUnique(teamFiltered, ownProjects)
            initiativeResults = ownInitiatives
        }

        return (projectResults + initiativeResults).sorted {
            ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast)
        }
    }

    /// Concatenates two update streams and drops duplicates, keeping
    /// the first occurrence. Used to union team-scoped and authored
    /// results without re-fetching individual records.
    private static func mergedUnique(
        _ primary: [LinearPulseUpdate],
        _ secondary: [LinearPulseUpdate]
    ) -> [LinearPulseUpdate] {
        var seen = Set<String>()
        var out: [LinearPulseUpdate] = []
        out.reserveCapacity(primary.count + secondary.count)
        for update in primary + secondary where seen.insert(update.id).inserted {
            out.append(update)
        }
        return out
    }

    // MARK: - Per-endpoint fetches

    private func fetchProjectUpdates(
        accessToken: String,
        accountEmail: String?,
        onlyMine: Bool,
        windowDays: Int
    ) async throws -> [LinearPulseUpdate] {
        let since = Self.windowStartIso(daysAgo: windowDays)
        let filterArg: String = {
            if onlyMine {
                return ", filter: { user: { isMe: { eq: true } }, createdAt: { gt: \"\(since)\" } }"
            } else {
                return ", filter: { createdAt: { gt: \"\(since)\" } }"
            }
        }()
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

        let variables: [String: Any] = ["first": Self.pulsePageSize(for: windowDays)]

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
        onlyMine: Bool,
        windowDays: Int
    ) async throws -> [LinearPulseUpdate] {
        let since = Self.windowStartIso(daysAgo: windowDays)
        let filterArg: String = {
            if onlyMine {
                return ", filter: { user: { isMe: { eq: true } }, createdAt: { gt: \"\(since)\" } }"
            } else {
                return ", filter: { createdAt: { gt: \"\(since)\" } }"
            }
        }()
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

        let variables: [String: Any] = ["first": Self.pulsePageSize(for: windowDays)]

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
