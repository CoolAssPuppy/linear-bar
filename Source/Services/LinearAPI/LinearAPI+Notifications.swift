import Foundation

extension LinearAPI {

    /// Page size for the Inbox tab. 50 fits the visible popover and leaves
    /// room for client-side unread filtering (Linear's server-side
    /// `NotificationFilter` input has drifted historically — see below).
    private static let notificationsPageSize = 50

    /// Fetches the viewer's unread notifications for the Inbox tab.
    ///
    /// Linear's `notifications` connection returns polymorphic subtypes;
    /// this query pulls the common base fields plus the two subtypes we
    /// display (IssueNotification, ProjectNotification). The
    /// DocumentNotification subtype is intentionally omitted — its schema
    /// shape has changed historically and a missing subtype here would
    /// reject the whole query.
    ///
    /// Unread filtering happens client-side. Server-side
    /// `filter: { readAt: { null: true } }` 400'd on at least one
    /// workspace; doing it in Swift costs one boolean check per node and
    /// is immune to future filter-shape drift.
    func fetchUnreadNotifications(
        accessToken: String,
        accountEmail: String? = nil,
        limit: Int = 50
    ) async throws -> [LinearNotification] {
        if TestDataProvider.isUITesting {
            return TestDataProvider.getUnreadNotifications()
        }

        let query = """
        query FetchInbox($first: Int!) {
          notifications(first: $first) {
            nodes {
              id
              type
              createdAt
              readAt
              snoozedUntilAt
              actor {
                id
                name
                displayName
                avatarUrl
              }
              ... on IssueNotification {
                issue {
                  id
                  identifier
                  title
                  url
                  team { id name key }
                }
              }
              ... on ProjectNotification {
                project {
                  id
                  name
                  url
                  color
                }
              }
            }
          }
        }
        """

        let variables: [String: Any] = ["first": min(limit, Self.notificationsPageSize)]

        struct Response: Decodable {
            struct NotificationsData: Decodable { let nodes: [LinearNotification] }
            let notifications: NotificationsData
        }

        let response: GraphQLResponse<Response> = try await execute(
            query: query,
            variables: variables,
            accessToken: accessToken,
            accountEmail: accountEmail
        )

        guard let data = response.data else { throw LinearError.invalidResponse }
        return data.notifications.nodes.filter { $0.readAt == nil }
    }

    /// Fetches the total unread notification count. Cheap scalar — drives
    /// the menu bar badge number.
    func fetchUnreadNotificationCount(
        accessToken: String,
        accountEmail: String? = nil
    ) async throws -> Int {
        if TestDataProvider.isUITesting {
            return TestDataProvider.getUnreadNotifications().count
        }

        let query = "query FetchUnreadCount { notificationsUnreadCount }"

        struct Response: Decodable { let notificationsUnreadCount: Int }

        let response: GraphQLResponse<Response> = try await execute(
            query: query,
            accessToken: accessToken,
            accountEmail: accountEmail
        )

        guard let data = response.data else { throw LinearError.invalidResponse }
        return data.notificationsUnreadCount
    }
}
