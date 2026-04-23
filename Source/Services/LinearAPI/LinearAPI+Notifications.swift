import Foundation

extension LinearAPI {

    /// Fetches the viewer's unread notifications for the Inbox tab.
    ///
    /// Linear's `notifications` connection returns polymorphic subtypes;
    /// this query pulls the common base fields plus the two subtypes we
    /// display (IssueNotification, ProjectNotification). The DocumentNotification
    /// subtype is intentionally omitted — its schema shape has changed
    /// historically and a missing subtype here would reject the whole query.
    func fetchUnreadNotifications(
        accessToken: String,
        accountEmail: String? = nil,
        limit: Int = 50
    ) async throws -> [LinearNotification] {
        if TestDataProvider.isUITesting {
            return TestDataProvider.getUnreadNotifications()
        }

        let query = """
        query Inbox($first: Int!) {
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
                  state { name type }
                  priority
                  priorityLabel
                  team { id name key }
                }
              }
              ... on ProjectNotification {
                project {
                  id
                  name
                  url
                  icon
                  color
                }
              }
            }
          }
        }
        """

        let variables: [String: Any] = ["first": limit]

        struct Response: Decodable {
            struct NotificationsData: Decodable {
                let nodes: [LinearNotification]
            }
            let notifications: NotificationsData
        }

        let response: GraphQLResponse<Response> = try await execute(
            query: query,
            variables: variables,
            accessToken: accessToken,
            accountEmail: accountEmail
        )

        guard let data = response.data else {
            throw LinearError.invalidResponse
        }

        // Filter client-side to just unread notifications. Doing this on the
        // server via the `filter` argument 400'd on some workspaces because
        // the NotificationFilter input shape has drifted.
        return data.notifications.nodes.filter { $0.readAt == nil }
    }

    /// Fetches the total unread notification count. Cheap scalar — drives the
    /// menu bar badge number.
    func fetchUnreadNotificationCount(
        accessToken: String,
        accountEmail: String? = nil
    ) async throws -> Int {
        if TestDataProvider.isUITesting {
            return TestDataProvider.getUnreadNotifications().count
        }

        let query = "query UnreadCount { notificationsUnreadCount }"

        struct Response: Decodable {
            let notificationsUnreadCount: Int
        }

        let response: GraphQLResponse<Response> = try await execute(
            query: query,
            accessToken: accessToken,
            accountEmail: accountEmail
        )

        guard let data = response.data else {
            throw LinearError.invalidResponse
        }

        return data.notificationsUnreadCount
    }
}
