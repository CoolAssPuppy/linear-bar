//  WelcomeView.swift
//  Linear Bar
//  Copyright (c) 2026 Strategic Nerds. All rights reserved.

import SwiftUI
import AppKit

/// Empty-state view shown when no Linear workspaces are connected, or when
/// the user clicks the "Add workspace" button in the sidebar.
///
struct LinearWelcomeView: View {
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            VStack(spacing: 28) {
                heroBadge

                VStack(spacing: 10) {
                    Text("Welcome to Menu Bar for Linear")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(theme.foreground)
                        .fixedSize()

                    Text("Connect a Linear workspace and Menu Bar for Linear will quietly keep your favorites, recent issues, and search one click away from the menu bar.")
                        .font(.system(size: 14))
                        .foregroundStyle(theme.muted)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 460)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(spacing: 12) {
                    AppProviderChoiceCard(
                        title: "Linear",
                        subtitle: "Connect via OAuth",
                        assetName: "AppIcon"
                    ) {
                        connectLinear()
                    }
                }
                .padding(.top, 4)

                trustSignals
                    .padding(.top, 4)
            }
            .padding(.horizontal, 32)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.background)
    }

    private var heroBadge: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            theme.primary.opacity(0.18),
                            theme.primaryDeep.opacity(0.06)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(theme.primary.opacity(0.25), lineWidth: 1)

            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [theme.primary, theme.primaryDeep],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 80, height: 80)
                .shadow(color: theme.primary.opacity(0.35), radius: 16, y: 8)
                .overlay(
                    Image(systemName: "checkmark.square.fill")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundStyle(.white)
                )
        }
        .frame(width: 96, height: 96)
    }

    private var trustSignals: some View {
        HStack(spacing: 14) {
            trustItem(icon: "lock.fill", label: "Tokens stored in macOS Keychain")

            Circle()
                .fill(theme.dim)
                .frame(width: 3, height: 3)

            trustItem(icon: "info.circle", label: "No telemetry, no analytics, no servers")
        }
    }

    private func trustItem(icon: String, label: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(theme.tertiary)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(theme.tertiary)
        }
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

#Preview {
    LinearWelcomeView()
        .frame(width: 820, height: 560)
}
