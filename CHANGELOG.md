# Changelog

All notable changes to IssueBar will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Future features will be listed here

### Changed
- Future changes will be listed here

### Fixed
- Future bug fixes will be listed here

## [1.0.0] - 2025-01-15

### Added
- Initial release of IssueBar
- Quick access to Linear from macOS menu bar
- View favorites, recent items, and search Linear workspace
- Multiple Linear account support with account switcher
- Secure OAuth authentication with Linear
- Smart filtering options (completed items, canceled items)
- Sort by creation date or last update
- iCloud sync for preferences across devices
- Customizable account colors
- Menu bar icon with dropdown interface
- Settings panel with:
  - Account management
  - Default view selection
  - Default tab configuration
  - Auto-refresh intervals
  - Display filters
  - Sort order options
- Native macOS design built with SwiftUI
- Credentials stored securely in macOS Keychain
- Privacy manifest (PrivacyInfo.xcprivacy)
- OAuth callback handling (issuebar:// URL scheme)
- App Store metadata and descriptions
- Automated deployment system with Fastlane
- Comprehensive logging with OSLog
- Color picker with hex input support
- About tab with version information

### Security
- OAuth 2.0 authentication with Linear
- Keychain storage for access tokens
- iCloud key-value store for secure preference sync
- App Sandbox enabled
- Hardened Runtime enabled
- Network connections to api.linear.app only

[Unreleased]: https://github.com/strategicnerds/linear-bar/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/strategicnerds/linear-bar/releases/tag/v1.0.0
