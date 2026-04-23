import Foundation

extension LinearAPI {

    /// Fetches the viewer's unread notifications. Used as the data source
    /// for the Inbox tab. Uses `readAt: { null: true }` so we only pull the
    /// actionable inbox; the snoozed / muted filter is handled by Linear's
    /// own notification rules on the server.
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
          notifications(first: $first, filter: { readAt: { null: true } }) {
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
                  slaBreachesAt
                }
                commentId
                reactionEmoji
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
              ... on DocumentNotification {
                document {
                  id
                  title
                  url
                  icon
                  color
                }
              }
              ... on OauthClientApprovalNotification { id }
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

        return data.notifications.nodes
    }

    /// Fetches the total unread notification count from Linear. Cheap — it's
    /// a single scalar — and drives the menu bar badge number.
    func fetchUnreadNotificationCount(
        accessToken: String,
        accountEmail: String? = nil
    ) async throws -> Int {
        if TestDataProvider.isUITesting {
            return TestDataProvider.getUnreadNotifications().count
        }

        let query = """
        query UnreadCount {
          notificationsUnreadCount
        }
        """

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
