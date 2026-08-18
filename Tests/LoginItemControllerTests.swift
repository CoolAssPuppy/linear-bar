import XCTest
@testable import LinearBar

@MainActor
final class LoginItemControllerTests: XCTestCase {
    func testReadsSystemStateInsteadOfSavedPreference() {
        let manager = LoginItemManagerSpy(isEnabled: true)

        let controller = LoginItemController(manager: manager)

        XCTAssertTrue(controller.isEnabled)
    }

    func testUpdatesSystemLoginItemWhenUserChangesToggle() {
        let manager = LoginItemManagerSpy(isEnabled: false)
        let controller = LoginItemController(manager: manager)

        controller.setEnabled(true)

        XCTAssertEqual(manager.requestedValues, [true])
        XCTAssertTrue(controller.isEnabled)
        XCTAssertNil(controller.errorMessage)
    }

    func testRestoresActualStateAndReportsRegistrationFailure() {
        let manager = LoginItemManagerSpy(
            isEnabled: false,
            error: LoginItemManagerSpy.TestError.registrationFailed
        )
        let controller = LoginItemController(manager: manager)

        controller.setEnabled(true)

        XCTAssertFalse(controller.isEnabled)
        XCTAssertEqual(controller.errorMessage, "Could not update Launch at Login. Please try again.")
    }

    func testMigratesEnabledLegacyPreferenceToSystemLoginItem() {
        let suiteName = "LoginItemControllerTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Could not create test preferences")
            return
        }
        defaults.set(true, forKey: "launchAtLogin")
        let manager = LoginItemManagerSpy(isEnabled: false)

        LoginItemController.migrateLegacyPreference(defaults: defaults, manager: manager)

        XCTAssertEqual(manager.requestedValues, [true])
        XCTAssertNil(defaults.object(forKey: "launchAtLogin"))
    }
}

@MainActor
private final class LoginItemManagerSpy: LoginItemManaging {
    enum TestError: Error {
        case registrationFailed
    }

    private(set) var isEnabled: Bool
    private(set) var requestedValues: [Bool] = []
    private let error: Error?

    init(isEnabled: Bool, error: Error? = nil) {
        self.isEnabled = isEnabled
        self.error = error
    }

    func setEnabled(_ isEnabled: Bool) throws {
        requestedValues.append(isEnabled)
        if let error {
            throw error
        }
        self.isEnabled = isEnabled
    }
}
