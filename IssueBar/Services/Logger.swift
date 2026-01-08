import Foundation
import os.log

/// Centralized logging utility for IssueBar
/// Uses OSLog for production-ready logging with proper levels
enum AppLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.issuebar"

    /// Logger for app lifecycle events
    static let app = OSLog(subsystem: subsystem, category: "App")

    /// Logger for authentication and authorization
    static let auth = OSLog(subsystem: subsystem, category: "Auth")

    /// Logger for API calls and networking
    static let api = OSLog(subsystem: subsystem, category: "API")

    /// Logger for settings and preferences
    static let settings = OSLog(subsystem: subsystem, category: "Settings")

    /// Logger for UI and view events
    static let ui = OSLog(subsystem: subsystem, category: "UI")

    /// Logger for keychain operations
    static let keychain = OSLog(subsystem: subsystem, category: "Keychain")

    /// Log a debug message
    static func debug(_ message: String, log: OSLog = .default, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        let fileName = (file as NSString).lastPathComponent
        os_log(.debug, log: log, "[%{public}@:%d %{public}@] %{public}@", fileName, line, function, message)
        #endif
    }

    /// Log an info message
    static func info(_ message: String, log: OSLog = .default) {
        os_log(.info, log: log, "%{public}@", message)
    }

    /// Log an error message
    static func error(_ message: String, log: OSLog = .default, error: Error? = nil) {
        if let error = error {
            os_log(.error, log: log, "%{public}@: %{public}@", message, error.localizedDescription)
        } else {
            os_log(.error, log: log, "%{public}@", message)
        }
    }

    /// Log a fault (critical error)
    static func fault(_ message: String, log: OSLog = .default) {
        os_log(.fault, log: log, "%{public}@", message)
    }
}
