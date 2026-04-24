import SwiftUI

/// Resolves the OAuth credentials a popover tab needs, or throws a typed
/// error when none are available. Collapses the UI-test shortcut + token
/// retrieval + "no authenticated account" check that used to live at the top
/// of every tab's `loadData()`.
enum PopoverSession {
    case demo
    case authenticated(accessToken: String, accountEmail: String)

    enum Error: LocalizedError {
        case noAuthenticatedAccount

        var errorDescription: String? {
            switch self {
            case .noAuthenticatedAccount:
                return "No authenticated account found. Please sign in."
            }
        }
    }

    /// Resolves the session up front. Throws `noAuthenticatedAccount` when
    /// no primary account is available — catch and surface via the view's
    /// `errorMessage` binding.
    @MainActor
    static func resolve() throws -> PopoverSession {
        if TestDataProvider.isUITesting {
            return .demo
        }
        guard let account = AppSettings.shared.primaryValidAccount,
              let token = KeychainService.shared.retrieveAccessToken(forAccount: account.email) else {
            throw Error.noAuthenticatedAccount
        }
        return .authenticated(accessToken: token, accountEmail: account.email)
    }

    var accessToken: String {
        switch self {
        case .demo:                             return "demo-token"
        case .authenticated(let token, _):      return token
        }
    }

    var accountEmail: String {
        switch self {
        case .demo:                             return "demo@example.com"
        case .authenticated(_, let email):      return email
        }
    }
}
