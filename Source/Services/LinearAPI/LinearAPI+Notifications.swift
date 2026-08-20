import Foundation

extension LinearAPI {

    private static let notificationsPageSize = 50
    private static let maxInboxPages = 8

    func fetchUnreadNotifications(
        accessToken: String,
        accountEmail: String? = nil,
        limit: Int = 50
    ) async throws -> [LinearNotification] {
        if TestDataProvider.isUITesting {
            return InboxCount.inboxItems(in: TestDataProvider.getUnreadNotifications())
        }

        var collected: [LinearNotification] = []
        var after: String?
        for _ in 0..<Self.maxInboxPages {
            let page = try await fetchNotificationPage(
                accessToken: accessToken,
                accountEmail: accountEmail,
                after: after
            )
            collected.append(contentsOf: page.nodes)
            let inbox = InboxCount.inboxItems(in: collected)
            if inbox.count >= limit || !page.hasNextPage {
                return Array(inbox.prefix(limit))
            }
            after = page.endCursor
        }
        return Array(InboxCount.inboxItems(in: collected).prefix(limit))
    }

    func fetchUnreadNotificationCount(
        accessToken: String,
        accountEmail: String? = nil
    ) async throws -> Int {
        if TestDataProvider.isUITesting {
            return InboxCount.unread(in: TestDataProvider.getUnreadNotifications())
        }

        var collected: [LinearNotification] = []
        var after: String?
        var complete = false
        for _ in 0..<Self.maxInboxPages {
            let page = try await fetchNotificationPage(
                accessToken: accessToken,
                accountEmail: accountEmail,
                after: after,
                fieldsOnly: true
            )
            collected.append(contentsOf: page.nodes)
            complete = !page.hasNextPage
            if complete { break }
            after = page.endCursor
        }

        let computed = InboxCount.unread(in: collected)
        if complete { return computed }

        // Incomplete scan: Linear's scalar is the full unread total.
        return max(computed, try await fetchNotificationsUnreadCountScalar(
            accessToken: accessToken,
            accountEmail: accountEmail
        ))
    }

    private func fetchNotificationsUnreadCountScalar(
        accessToken: String,
        accountEmail: String?
    ) async throws -> Int {
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

    private struct NotificationPage {
        let nodes: [LinearNotification]
        let hasNextPage: Bool
        let endCursor: String?
    }

    private func fetchNotificationPage(
        accessToken: String,
        accountEmail: String?,
        after: String?,
        fieldsOnly: Bool = false
    ) async throws -> NotificationPage {
        let nodeFields = fieldsOnly
            ? """
              id
              type
              createdAt
              readAt
              archivedAt
              snoozedUntilAt
              groupingKey
              groupingPriority
              """
            : """
              id
              type
              createdAt
              readAt
              archivedAt
              snoozedUntilAt
              groupingKey
              groupingPriority
              title
              subtitle
              url
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
              """

        let query = """
        query FetchInbox($first: Int!, $after: String) {
          notifications(first: $first, after: $after) {
            pageInfo { hasNextPage endCursor }
            nodes {
              \(nodeFields)
            }
          }
        }
        """

        var variables: [String: Any] = ["first": Self.notificationsPageSize]
        if let after { variables["after"] = after }

        struct Response: Decodable {
            struct PageInfo: Decodable {
                let hasNextPage: Bool
                let endCursor: String?
            }
            struct NotificationsData: Decodable {
                let nodes: [LinearNotification]
                let pageInfo: PageInfo
            }
            let notifications: NotificationsData
        }

        let response: GraphQLResponse<Response> = try await execute(
            query: query,
            variables: variables,
            accessToken: accessToken,
            accountEmail: accountEmail
        )

        guard let data = response.data else { throw LinearError.invalidResponse }
        return NotificationPage(
            nodes: data.notifications.nodes,
            hasNextPage: data.notifications.pageInfo.hasNextPage,
            endCursor: data.notifications.pageInfo.endCursor
        )
    }
}
