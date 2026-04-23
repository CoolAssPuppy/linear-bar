import SwiftUI

/// Project icon: colored square with three filled quadrants. Mirrors
/// Linear's project iconography so artifact type reads at a glance across
/// Inbox, Recent, and Search.
struct ProjectGlyph: View {
    let color: String?

    @Environment(\.theme) private var theme

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                .fill(tint)
            quadrantOverlay
        }
        .frame(width: 10, height: 10)
    }

    private var tint: Color {
        if let color { return Color(hex: color) }
        return theme.warning
    }

    private var quadrantOverlay: some View {
        GeometryReader { proxy in
            let half = proxy.size.width / 2
            Path { path in
                path.addRect(CGRect(x: 0, y: 0, width: half, height: half))
                path.addRect(CGRect(x: half, y: 0, width: half, height: half))
                path.addRect(CGRect(x: 0, y: half, width: half, height: half))
            }
            .fill(Color.white.opacity(0.35))
        }
    }
}

/// Initiative icon: outlined diamond. Visually distinct from both the
/// project square and the issue state circle so rows mixing all three
/// artifact types remain scannable.
struct InitiativeGlyph: View {
    @Environment(\.theme) private var theme

    var body: some View {
        ZStack {
            diamond.fill(initiativeColor.opacity(0.18))
            diamond.stroke(initiativeColor, lineWidth: 1.2)
        }
        .frame(width: 10, height: 10)
    }

    private var diamond: Path {
        Path { path in
            path.move(to: CGPoint(x: 5, y: 0))
            path.addLine(to: CGPoint(x: 10, y: 5))
            path.addLine(to: CGPoint(x: 5, y: 10))
            path.addLine(to: CGPoint(x: 0, y: 5))
            path.closeSubpath()
        }
    }

    private var initiativeColor: Color { Color(hex: "#BB6BD9") }
}
