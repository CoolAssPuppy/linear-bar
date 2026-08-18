import CryptoKit
import Foundation
import Security

enum OAuthPKCE {
    enum GenerationError: Error {
        case randomBytes(OSStatus)
    }

    static func generateVerifier() throws -> String {
        try generateURLSafeString(byteCount: 32)
    }

    static func generateState() throws -> String {
        try generateURLSafeString(byteCount: 32)
    }

    static func challenge(for verifier: String) -> String {
        let digest = SHA256.hash(data: Data(verifier.utf8))
        return Data(digest).base64URLEncodedString()
    }

    private static func generateURLSafeString(byteCount: Int) throws -> String {
        var bytes = [UInt8](repeating: 0, count: byteCount)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        guard status == errSecSuccess else {
            throw GenerationError.randomBytes(status)
        }
        return Data(bytes).base64URLEncodedString()
    }
}

private extension Data {
    func base64URLEncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
