# Privacy Policy for LinearBar

**Last Updated**: January 2025

## Our Commitment to Privacy

LinearBar is designed with privacy as a core principle. We believe your work data belongs to you, and only you.

## Data Collection

**LinearBar does not collect, store, or transmit any personal data to our servers.**

We do not operate any backend servers, analytics services, or tracking systems. All data handling happens locally on your Mac or in your personal iCloud account.

## How Your Data is Stored

### Local Storage (macOS Keychain)
Your Linear OAuth access tokens are stored securely in the macOS Keychain. This is Apple's encrypted credential storage system that requires your Mac password or Touch ID to access.

**What's stored:**
- OAuth access token for Linear API authentication
- OAuth refresh token (if applicable)

**Who can access it:**
- Only you, on your Mac
- Apps you explicitly authorize via macOS Keychain
- Not accessible to us or any third parties

### iCloud Key-Value Store (Optional)
If you have iCloud enabled, your app preferences are synced across your Macs using Apple's iCloud Key-Value Store.

**What's synced:**
- Default view preferences (Favorites, Recent, Search)
- Filter settings (show/hide completed and canceled items)
- Sort order preferences
- Selected team ID
- Refresh interval settings
- Launch at login preference

**What's NOT synced:**
- OAuth tokens or credentials
- Your Linear account data
- Any work items, issues, or projects
- Personal information

**Who can access it:**
- Only you, via your iCloud account
- Encrypted and managed by Apple
- Not accessible to us or any third parties

## Third-Party Services

### Linear API
LinearBar connects directly to Linear's API (api.linear.app) using OAuth 2.0 authentication.

**What data is sent to Linear:**
- Your OAuth credentials (for authentication)
- API requests for your work items (favorites, issues, projects)
- Search queries (when you use the search feature)

**Privacy Note:** All communication with Linear is subject to [Linear's Privacy Policy](https://linear.app/privacy). We recommend reviewing their policy to understand how Linear handles your data.

### Apple Services
LinearBar uses standard Apple frameworks:
- **macOS Keychain**: For secure credential storage
- **iCloud Key-Value Store**: For preferences sync (optional)
- **StoreKit**: For In-App Purchases (Buy Me Coffee)

All data handling through Apple services is subject to [Apple's Privacy Policy](https://www.apple.com/legal/privacy/).

## Data We Never Access

- Your Linear work items, issues, or projects
- Your Linear account credentials
- Your personal information
- Your usage patterns or analytics
- Your search queries or browsing history

## In-App Purchases

If you choose to purchase "Buy Me Coffee":
- The transaction is processed entirely by Apple through StoreKit
- We do not collect or store your payment information
- Apple handles all payment processing according to their privacy policy
- Your purchase is recorded locally on your device for purchase restoration

## Open Source Transparency

LinearBar is open source. You can review the complete source code at:
https://github.com/coolasspuppy/linear-bar

This means:
- Anyone can verify our privacy claims
- Security researchers can audit the code
- You can see exactly what data is accessed and how

## Network Connections

LinearBar only makes network connections to:
1. **Linear's API** (api.linear.app) - for fetching your work items
2. **Linear's OAuth** (linear.app/oauth) - during authentication
3. **Apple's servers** - for iCloud sync and StoreKit (if you use these features)

We never connect to:
- Third-party analytics services
- Advertisement networks
- Tracking or telemetry services
- Our own backend servers (we don't have any)

## Your Rights

Since we don't collect or store your data:
- **Right to Access**: All your data is on your Mac and in your iCloud account
- **Right to Delete**: Uninstall the app and delete iCloud data in System Settings
- **Right to Export**: Your data is already in your control
- **Right to Portability**: Your data stays with Linear and Apple

## Children's Privacy

LinearBar does not collect any information from users. There are no age restrictions beyond Linear's own requirements for using their service.

## Changes to This Privacy Policy

We may update this privacy policy from time to time. Changes will be posted to this repository with an updated "Last Updated" date.

## California Privacy Rights (CCPA)

Under the California Consumer Privacy Act (CCPA):
- We do not sell personal information
- We do not collect personal information
- We do not share personal information with third parties

## European Privacy Rights (GDPR)

Under the General Data Protection Regulation (GDPR):
- We do not process personal data
- We do not transfer data internationally (except to Linear's API)
- All data processing happens locally on your device

## Contact

For privacy questions or concerns:
- Open an issue: https://github.com/coolasspuppy/linear-bar/issues
- Email: [Create an issue on GitHub for privacy inquiries]

## Third-Party Privacy Policies

- Linear: https://linear.app/privacy
- Apple: https://www.apple.com/legal/privacy/

---

**Summary**: LinearBar respects your privacy by design. We built it to work entirely on your device, with your iCloud, and your Linear account. We never see your data, collect analytics, or operate backend servers. What you see in the code is what you get.
