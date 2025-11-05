import Foundation
import AppKit

/// Represents a Linear account with OAuth credentials
struct LinearAccount: Codable, Identifiable, Hashable {
    var id: String { email }
    var email: String
    var name: String?
    var isEnabled: Bool = true
    var authStatus: AuthStatus = .valid
    var lastAuthError: Date?
    var color: String? // Hex color for this account

    var displayName: String {
        name ?? email
    }
}

enum AuthStatus: String, Codable {
    case valid
    case expired
    case revoked
    case needsAuth // Account synced from iCloud but no local OAuth tokens
}

extension LinearAccount {
    static let preview = LinearAccount(
        email: "user@example.com",
        name: "John Doe",
        isEnabled: true,
        color: "#5E6AD2"
    )
}
