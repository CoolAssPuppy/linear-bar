import Foundation
import Security
import os.log

/// Service for securely storing and retrieving Linear OAuth tokens in the system Keychain
@MainActor
class KeychainService {
    static let shared = KeychainService()
    private let serviceName = "com.strategicnerds.LinearBar"

    private init() {}

    // MARK: - Public Methods

    /// Saves an access token for a Linear account
    func saveAccessToken(_ token: String, forAccount account: String) -> Bool {
        save(token: token, forAccount: "\(account)_access")
    }

    /// Retrieves the access token for a Linear account
    func retrieveAccessToken(forAccount account: String) -> String? {
        #if DEBUG
        // Return fake token for UI testing
        if CommandLine.arguments.contains("--uitesting") {
            return "fake-test-token-for-ui-testing"
        }
        #endif

        return retrieve(forAccount: "\(account)_access")
    }

    /// Deletes the access token for a Linear account
    func deleteAccessToken(forAccount account: String) -> Bool {
        delete(forAccount: "\(account)_access")
    }

    /// Saves a refresh token for a Linear account
    func saveRefreshToken(_ token: String, forAccount account: String) -> Bool {
        save(token: token, forAccount: "\(account)_refresh")
    }

    /// Retrieves the refresh token for a Linear account
    func retrieveRefreshToken(forAccount account: String) -> String? {
        retrieve(forAccount: "\(account)_refresh")
    }

    /// Deletes the refresh token for a Linear account
    func deleteRefreshToken(forAccount account: String) -> Bool {
        delete(forAccount: "\(account)_refresh")
    }

    /// Deletes all tokens for a Linear account
    func deleteAllTokens(forAccount account: String) -> Bool {
        let accessDeleted = deleteAccessToken(forAccount: account)
        let refreshDeleted = deleteRefreshToken(forAccount: account)
        return accessDeleted && refreshDeleted
    }

    // MARK: - Private Methods

    private func save(token: String, forAccount account: String) -> Bool {
        guard let tokenData = token.data(using: .utf8) else {
            AppLogger.error("Failed to encode token as UTF-8 for account: \(account)", log: AppLogger.keychain)
            return false
        }

        let searchQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: tokenData,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        // Try to update existing item first
        let updateStatus = SecItemUpdate(searchQuery as CFDictionary, attributes as CFDictionary)

        if updateStatus == errSecSuccess {
            AppLogger.debug("Successfully updated token for \(account)", log: AppLogger.keychain)
            return true
        } else if updateStatus == errSecItemNotFound {
            // Item doesn't exist, try to add it
            AppLogger.debug("No existing item for \(account), attempting to add new item", log: AppLogger.keychain)

            var addQuery = searchQuery
            addQuery[kSecValueData as String] = tokenData
            addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock

            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)

            if addStatus == errSecSuccess {
                AppLogger.debug("Successfully added token for \(account)", log: AppLogger.keychain)
                return true
            } else if addStatus == errSecDuplicateItem || addStatus == -2147413719 {
                // Duplicate item error - try aggressive cleanup
                AppLogger.info("Duplicate item detected for \(account), attempting cleanup and retry", log: AppLogger.keychain)

                // Try deleting with comprehensive query
                let cleanupQuery: [String: Any] = [
                    kSecClass as String: kSecClassGenericPassword,
                    kSecAttrService as String: serviceName,
                    kSecAttrAccount as String: account,
                    kSecMatchLimit as String: kSecMatchLimitAll
                ]

                let deleteStatus = SecItemDelete(cleanupQuery as CFDictionary)
                AppLogger.debug("Cleanup delete result: \(deleteStatus) (\(keychainErrorMessage(deleteStatus)))", log: AppLogger.keychain)

                // Retry add after cleanup
                let retryStatus = SecItemAdd(addQuery as CFDictionary, nil)
                if retryStatus == errSecSuccess {
                    AppLogger.debug("Successfully added token after cleanup for \(account)", log: AppLogger.keychain)
                    return true
                } else {
                    AppLogger.error("Failed to add token even after cleanup for \(account). Status: \(retryStatus) (\(keychainErrorMessage(retryStatus)))", log: AppLogger.keychain)
                    return false
                }
            } else {
                AppLogger.error("Failed to add token for \(account). Status: \(addStatus) (\(keychainErrorMessage(addStatus)))", log: AppLogger.keychain)
                return false
            }
        } else {
            AppLogger.error("Failed to update token for \(account). Status: \(updateStatus) (\(keychainErrorMessage(updateStatus)))", log: AppLogger.keychain)
            return false
        }
    }

    private func retrieve(forAccount account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            if status != errSecItemNotFound {
                AppLogger.error("Failed to retrieve token for \(account). Status: \(status) (\(keychainErrorMessage(status)))", log: AppLogger.keychain)
            }
            return nil
        }

        return token
    }

    private func delete(forAccount account: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account
        ]

        let status = SecItemDelete(query as CFDictionary)
        let success = status == errSecSuccess || status == errSecItemNotFound

        if !success {
            AppLogger.error("Failed to delete token for \(account). Status: \(status) (\(keychainErrorMessage(status)))", log: AppLogger.keychain)
        }

        return success
    }

    private func keychainErrorMessage(_ status: OSStatus) -> String {
        switch status {
        case errSecSuccess:
            return "Success"
        case errSecDuplicateItem:
            return "Duplicate item"
        case errSecItemNotFound:
            return "Item not found"
        case errSecAuthFailed:
            return "Authentication failed"
        case errSecNotAvailable:
            return "Keychain not available"
        case errSecParam:
            return "Invalid parameters"
        case errSecAllocate:
            return "Memory allocation failed"
        case errSecInteractionNotAllowed:
            return "User interaction not allowed"
        case errSecMissingEntitlement:
            return "Missing entitlement"
        default:
            return "Unknown error code: \(status)"
        }
    }
}
