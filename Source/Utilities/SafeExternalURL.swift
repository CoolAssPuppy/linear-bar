import Foundation
import AppKit

/// Centralized URL validation for links that leave the app process.
/// This avoids repeating ad-hoc `URL(string:)` parsing in views and
/// ensures all user/API-provided links are restricted to expected hosts.
enum SafeExternalURL {
    private static let linearHosts: Set<String> = ["linear.app", "www.linear.app"]
    private static let allowedSchemes: Set<String> = ["https"]

    /// Parses and validates a Linear web URL provided by API payloads.
    static func linearURL(from raw: String) -> URL? {
        validatedURL(from: raw, allowedHosts: linearHosts)
    }

    /// Parses and validates a generic HTTPS URL.
    static func httpsURL(from raw: String) -> URL? {
        guard let components = URLComponents(string: raw),
              components.scheme?.lowercased() == "https",
              components.host?.isEmpty == false else {
            return nil
        }
        return components.url
    }

    /// Builds a Linear URL from untrusted path segments.
    /// Each segment is percent-encoded, preventing path/query injection.
    static func linearURL(orgSlug: String, pathComponents: [String]) -> URL? {
        let allComponents = [orgSlug] + pathComponents
        let encodedPath = allComponents
            .map { $0.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "" }
            .joined(separator: "/")

        var components = URLComponents()
        components.scheme = "https"
        components.host = "linear.app"
        components.percentEncodedPath = "/" + encodedPath
        return components.url
    }

    /// Opens a URL only if it passes expected scheme/host constraints.
    @discardableResult
    static func openLinearURL(from raw: String) -> Bool {
        guard let url = linearURL(from: raw) else { return false }
        return NSWorkspace.shared.open(url)
    }

    /// Parses a compile-time constant URL string. Traps with a clear message
    /// if the string is malformed. Use for URLs baked into the source, never
    /// for runtime/user input.
    static func mustParse(_ raw: StaticString) -> URL {
        guard let url = URL(string: "\(raw)") else {
            preconditionFailure("Invalid compile-time URL: \(raw)")
        }
        return url
    }

    private static func validatedURL(from raw: String, allowedHosts: Set<String>) -> URL? {
        guard let components = URLComponents(string: raw),
              let scheme = components.scheme?.lowercased(),
              allowedSchemes.contains(scheme),
              let host = components.host?.lowercased(),
              allowedHosts.contains(host),
              let url = components.url else {
            return nil
        }
        return url
    }
}
