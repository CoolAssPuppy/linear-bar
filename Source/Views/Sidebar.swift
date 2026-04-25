//  Sidebar.swift
//  Linear Bar
//  Copyright (c) 2026 Strategic Nerds. All rights reserved.

import SwiftUI

/// Left-hand sidebar for the main window: brand header, workspaces list,
/// and a footer that can open the Settings drawer.
///
struct LinearSidebar: View {
    @ObservedObject private var settings = AppSettings.shared
    @Environment(\.theme) private var theme
    @Binding var selection: String?
    var onOpenSettings: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            brandHeader

            sectionLabel

            accountsList

            Spacer(minLength: 0)

            footer
        }
        .frame(maxHeight: .infinity)
        .background(theme.surface)
        .overlay(
            Rectangle()
                .fill(theme.divider)
                .frame(width: 1),
            alignment: .trailing
        )
    }

    // MARK: - Header

    private var brandHeader: some View {
        HStack(spacing: 10) {
            BrandMark()

            VStack(alignment: .leading, spacing: 1) {
                Text("Menu Bar for Linear")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(theme.foreground)
                Text(subtitleText)
                    .font(.system(size: 10))
                    .foregroundStyle(theme.muted)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 28)
        .padding(.bottom, 10)
    }

    private var subtitleText: String {
        if settings.accounts.isEmpty {
            return "Setup required"
        }
        let count = settings.accounts.count
        return count == 1 ? "1 workspace" : "\(count) workspaces"
    }

    private var sectionLabel: some View {
        HStack {
            Text("WORKSPACES")
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.6)
                .foregroundStyle(theme.tertiary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 6)
    }

    // MARK: - Accounts list

    private var accountsList: some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                ForEach(settings.accounts) { account in
                    SidebarAccountRow(
                        account: account,
                        isSelected: selection == account.email
                    )
                    .onTapGesture {
                        selection = account.email
                    }
                }
            }
            .padding(.horizontal, 8)
        }
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 8) {
            Button(action: { selection = "welcome" }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .bold))
                    Text("Add workspace")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(theme.foreground)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                        .fill(theme.card)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                        .foregroundStyle(theme.borderStrong)
                )
            }
            .buttonStyle(.plain)

            Button(action: onOpenSettings) {
                Image(systemName: "gearshape")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(theme.muted)
                    .frame(width: 34, height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                            .fill(theme.card)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                            .strokeBorder(theme.borderStrong, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .keyboardShortcut(",", modifiers: .command)
            .help("Settings (⌘,)")
        }
        .padding(12)
        .overlay(
            Rectangle()
                .fill(theme.divider)
                .frame(height: 1),
            alignment: .top
        )
    }
}

// MARK: - Brand mark

private struct BrandMark: View {
    var body: some View {
        CheckmarkBrandMark(size: 24, glyphSize: 14)
    }
}

// MARK: - Row

private struct SidebarAccountRow: View {
    let account: LinearAccount
    let isSelected: Bool

    @Environment(\.theme) private var theme
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 10) {
            WorkspaceLogo(account: account, size: 22)
                .overlay(
                    RoundedRectangle(cornerRadius: 22 * 0.22, style: .continuous)
                        .strokeBorder(theme.borderStrong, lineWidth: 1)
                )
                .opacity(account.isEnabled ? 1 : 0.55)

            VStack(alignment: .leading, spacing: 1) {
                Text(account.displayName)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(textColor)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundStyle(theme.tertiary)
                    .lineLimit(1)
            }

            Spacer(minLength: 6)

            trailingBadge
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(background)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .strokeBorder(
                    isSelected ? theme.primary.opacity(0.25) : Color.clear,
                    lineWidth: 1
                )
        )
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .opacity(account.isEnabled ? 1 : 0.55)
    }

    private var subtitle: String {
        if let slug = account.organizationSlug, !slug.isEmpty {
            return "\(slug).linear.app"
        }
        return "Linear"
    }

    private var textColor: Color {
        isSelected ? theme.foreground : theme.foregroundSoft
    }

    @ViewBuilder
    private var background: some View {
        if isSelected {
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .fill(theme.primary.opacity(0.10))
        } else if isHovered {
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .fill(Color.white.opacity(0.02))
        } else {
            Color.clear
        }
    }

    @ViewBuilder
    private var trailingBadge: some View {
        if !account.isEnabled {
            Text("Off")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(theme.tertiary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule().fill(theme.cardElevated)
                )
        } else if account.authStatus != .valid {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(theme.warning)
                .help(account.authStatus == .needsAuth ? "Sign in required" : "Authentication expired")
        }
    }
}

#Preview {
    LinearSidebar(selection: .constant(nil))
        .frame(width: 260, height: 560)
}
