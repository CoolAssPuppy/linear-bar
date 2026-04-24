import SwiftUI

/// Shared empty / error / no-account placeholder. Three visually-similar
/// views (EmptyStateView, ErrorStateView, NoAccountView) collapsed into one
/// component parameterized by icon, title, subtitle, and tint.
struct StatePlaceholderView<Action: View>: View {
    let systemImage: String
    let title: String
    let subtitle: String
    var tint: Tint = .neutral
    @ViewBuilder var action: () -> Action

    @Environment(\.theme) private var theme

    enum Tint {
        case neutral
        case destructive
        case primary
    }

    var body: some View {
        VStack(spacing: 12) {
            Spacer(minLength: 0)

            ZStack {
                Image(systemName: systemImage)
                    .font(.system(size: 22, weight: .light))
                    .foregroundStyle(iconColor)
            }
            .frame(width: 56, height: 56)
            .appSurface(radius: 14, fill: badgeFill, border: badgeBorder)

            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(theme.foreground)

                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(theme.muted)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 260)
            }

            action()

            Spacer(minLength: 0)
        }
        .padding()
    }

    private var iconColor: Color {
        switch tint {
        case .neutral:     return theme.muted
        case .destructive: return theme.destructive
        case .primary:     return theme.primary
        }
    }

    private var badgeFill: Color {
        switch tint {
        case .neutral:     return theme.card
        case .destructive: return theme.destructive.opacity(0.1)
        case .primary:     return theme.primary.opacity(0.1)
        }
    }

    private var badgeBorder: Color {
        switch tint {
        case .neutral:     return theme.border
        case .destructive: return theme.destructive.opacity(0.3)
        case .primary:     return theme.primary.opacity(0.3)
        }
    }
}

extension StatePlaceholderView where Action == EmptyView {
    init(systemImage: String, title: String, subtitle: String, tint: Tint = .neutral) {
        self.init(systemImage: systemImage, title: title, subtitle: subtitle, tint: tint) {
            EmptyView()
        }
    }
}
