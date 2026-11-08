import SwiftUI
import AppKit

/// Shown inside the popover when no Linear accounts are connected. A compact
/// counterpart to `LinearWelcomeView` (which targets the main window). See
/// Paper artboard "Popover - Welcome".
struct PopoverWelcomeView: View {
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 0) {
            hero
                .padding(.top, 28)
                .padding(.bottom, 24)

            connectCard
                .padding(.horizontal, 18)
                .padding(.bottom, 22)

            Spacer(minLength: 0)

            footer
                .padding(.bottom, 14)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.background)
    }

    // MARK: - Hero

    private var hero: some View {
        VStack(spacing: 16) {
            CheckmarkBrandMark(size: 64, glyphSize: 32)

            VStack(spacing: 8) {
                Text("Menu Bar for Linear")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(theme.foreground)

                Text("A glanceable menu bar companion for Linear. Connect a workspace to see what needs your attention.")
                    .font(.system(size: 12))
                    .foregroundStyle(theme.muted)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 300)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Connect card

    private var connectCard: some View {
        Button(action: connectLinear) {
            HStack(spacing: 12) {
                CheckmarkBrandMark(size: 34, glyphSize: 18)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Connect Linear workspace")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(theme.foreground)
                    Text("OAuth via linear.app · read-only by default")
                        .font(.system(size: 10))
                        .foregroundStyle(theme.muted)
                }

                Spacer(minLength: 6)

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(theme.tertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                    .fill(theme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                    .strokeBorder(theme.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 8) {
            footerLink("Privacy policy", url: "https://github.com/strategicnerds/linear-bar/blob/main/PRIVACY.md")
            footerDot
            footerLink("Source on GitHub", url: "https://github.com/strategicnerds/linear-bar")
            footerDot
            Text("v\(appVersion)")
                .font(.system(size: 10))
                .foregroundStyle(theme.tertiary)
        }
    }

    private var footerDot: some View {
        Circle()
            .fill(theme.dim)
            .frame(width: 3, height: 3)
    }

    private func footerLink(_ title: String, url: String) -> some View {
        Button {
            if let parsed = SafeExternalURL.httpsURL(from: url) {
                NSWorkspace.shared.open(parsed)
            }
        } label: {
            Text(title)
                .font(.system(size: 10))
                .foregroundStyle(theme.muted)
        }
        .buttonStyle(.plain)
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "2.0.0"
    }

    // MARK: - Actions

    private func connectLinear() {
        LinearAuthService.shared.addLinearAccount { result in
            Task { @MainActor in
                switch result {
                case .success(let account):
                    NotificationCenter.default.post(name: .accountSelected, object: account)
                case .failure(let error):
                    let alert = NSAlert()
                    alert.messageText = "Could not connect to Linear"
                    alert.informativeText = error.localizedDescription
                    alert.alertStyle = .warning
                    alert.runModal()
                }
            }
        }
    }
}
