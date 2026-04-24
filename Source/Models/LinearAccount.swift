import Foundation
import AppKit

/// Represents a Linear account with OAuth credentials
struct LinearAccount: Codable, Identifiable, Hashable {
    var id: String { email }
    var email: String
    var name: String?
    var organizationSlug: String? // Organization URL key (e.g., "supabase")
    /// Human-readable workspace name (e.g., "Supabase"). Present on accounts
    /// added after the logo fetch landed; older records fall back to the
    /// slug.
    var organizationName: String?
    /// Absolute URL to the workspace logo on Linear's CDN. Optional — not
    /// every workspace uploads one.
    var organizationLogoUrl: String?
    var isEnabled: Bool = true
    var authStatus: AuthStatus = .valid
    var lastAuthError: Date?
    var color: String? // Hex color for this account

    var displayName: String {
        name ?? email
    }

    /// Preferred label for the workspace: the name if present, otherwise the
    /// slug, otherwise the email's domain. Every popover surface uses this
    /// so the fallback chain is in one place.
    var workspaceLabel: String {
        if let name = organizationName, !name.isEmpty { return name }
        if let slug = organizationSlug, !slug.isEmpty { return slug }
        return email.split(separator: "@").last.map(String.init) ?? email
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
