import XCTest
@testable import LinearBar

final class LinearNotificationPresentationTests: XCTestCase {
    func testCommonNotificationFieldsProvidePresentationAndTarget() throws {
        let json = """
        {
          "id": "notification-1",
          "type": "postUpdated",
          "createdAt": "2026-08-18T06:30:00.000Z",
          "readAt": null,
          "archivedAt": null,
          "snoozedUntilAt": null,
          "title": "Planning update",
          "subtitle": "Mike updated a post",
          "url": "https://linear.app/acme/post/planning-update",
          "actor": {
            "id": "user-1",
            "name": "Mike Nguyen",
            "displayName": "mike.nguyen0105",
            "avatarUrl": null
          }
        }
        """

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let notification = try decoder.decode(LinearNotification.self, from: Data(json.utf8))

        XCTAssertEqual(notification.presentationTitle, "Planning update")
        XCTAssertEqual(notification.presentationSubtitle, "Mike updated a post")
        XCTAssertEqual(
            notification.targetURL?.absoluteString,
            "https://linear.app/acme/post/planning-update"
        )
    }

    func testSubtypeTargetRemainsACompleteFallback() {
        let notification = LinearNotification(
            id: "notification-2",
            type: "issueMention",
            createdAt: nil,
            readAt: nil,
            archivedAt: nil,
            snoozedUntilAt: nil,
            actor: NotificationActor(
                id: "user-2",
                name: "Ari",
                displayName: "Ari",
                avatarUrl: nil
            ),
            issue: NotificationIssueTarget(
                id: "issue-1",
                identifier: "ENG-42",
                title: "Fix notification links",
                url: "https://linear.app/acme/issue/ENG-42/fix-notification-links",
                state: nil,
                priority: nil,
                priorityLabel: nil,
                team: nil
            ),
            project: nil,
            document: nil
        )

        XCTAssertEqual(notification.presentationTitle, "Fix notification links")
        XCTAssertEqual(notification.presentationSubtitle, "Ari mentioned you")
        XCTAssertNotNil(notification.targetURL)
    }
}
