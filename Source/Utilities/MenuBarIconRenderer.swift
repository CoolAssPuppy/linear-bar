import AppKit

/// Logical states the menu bar icon can display. `MenuBarManager` maps app
/// state (unread count, auth status, reachability, sync activity) to one of
/// these, and `MenuBarIconRenderer` produces the corresponding NSImage.
enum MenuBarIconState: Equatable {
    /// Default idle state. No badge, no accent.
    case quiet

    /// The viewer has unread notifications. Count is rendered next to the glyph.
    case unread(count: Int)

    /// One or more SLA alerts are imminent or breached. Count next to glyph,
    /// red dot overlay top-right. Takes priority over `.unread`.
    case urgent(count: Int)

    /// A sync is in progress. Glyph is dimmed.
    case syncing

    /// At least one account is in re-auth. Grey glyph with an orange X.
    case needsAuth

    /// No reachable network. Grey glyph with a slash.
    case offline
}

/// Renders the six menu bar icon states the design system defines. Template
/// variants (quiet, unread, syncing, offline) let the OS tint the image for
/// light/dark menu bars; non-template variants (urgent, needsAuth) draw their
/// own colors because the accent is semantic.
enum MenuBarIconRenderer {
    /// Final rendered image is sized to 22×18 so the optional unread count
    /// has room without forcing variable-width menu bar behavior on empty
    /// states. Height matches Apple's typical menu bar icon height of 18pt.
    private static let iconSize = NSSize(width: 22, height: 18)

    /// Glyph path drawn at 12×12. Five parallel strokes, matching the
    /// Linear Bar brand mark used throughout the popover.
    private static let glyphBoxSize: CGFloat = 12
    private static let glyphStrokeWidth: CGFloat = 1.2

    static func image(for state: MenuBarIconState) -> NSImage {
        let image = NSImage(size: iconSize)
        image.lockFocus()
        defer { image.unlockFocus() }

        let context = NSGraphicsContext.current?.cgContext
        context?.saveGState()
        defer { context?.restoreGState() }

        switch state {
        case .quiet:
            drawGlyph(alpha: 1, color: .black)
            image.isTemplate = true
        case .unread(let count):
            drawGlyph(alpha: 1, color: .black)
            drawCount(count, color: .black)
            image.isTemplate = true
        case .urgent(let count):
            drawGlyph(alpha: 1, color: NSColor(srgbRed: 0xED/255.0, green: 0xEF/255.0, blue: 0xF7/255.0, alpha: 1))
            drawCount(count, color: NSColor(srgbRed: 0xED/255.0, green: 0xEF/255.0, blue: 0xF7/255.0, alpha: 1))
            drawUrgentDot()
            image.isTemplate = false
        case .syncing:
            drawGlyph(alpha: 0.55, color: .black)
            image.isTemplate = true
        case .needsAuth:
            drawGlyph(alpha: 1, color: NSColor(srgbRed: 0x5E/255.0, green: 0x60/255.0, blue: 0x76/255.0, alpha: 1))
            drawAuthMark()
            image.isTemplate = false
        case .offline:
            drawGlyph(alpha: 1, color: .black)
            drawOfflineSlash()
            image.isTemplate = true
        }

        return image
    }

    // MARK: - Glyph

    /// Linear-style wordmark: five parallel diagonals on a 12×12 grid,
    /// left-aligned inside the 22×18 icon box.
    private static func drawGlyph(alpha: CGFloat, color: NSColor) {
        let path = NSBezierPath()
        // Coordinates here match the SVG used in the Paper design so the menu
        // bar icon visually reads as the same mark as the popover brand.
        let strokes: [(CGPoint, CGPoint)] = [
            (CGPoint(x: 1.2, y: 6.4),  CGPoint(x: 5.6, y: 10.8)),
            (CGPoint(x: 1.2, y: 3.4),  CGPoint(x: 8.6, y: 10.8)),
            (CGPoint(x: 2.2, y: 1.2),  CGPoint(x: 10.8, y: 9.8)),
            (CGPoint(x: 5.2, y: 1.2),  CGPoint(x: 10.8, y: 6.8)),
            (CGPoint(x: 8.2, y: 1.2),  CGPoint(x: 10.8, y: 3.8))
        ]

        // Translate glyph into the icon's left side, vertically centered.
        // NSImage coordinates put origin bottom-left; the SVG path uses
        // top-left, so we mirror y against the glyph box.
        let originX: CGFloat = 3
        let originY: CGFloat = (iconSize.height - glyphBoxSize) / 2

        for (from, to) in strokes {
            let fromPoint = CGPoint(
                x: originX + from.x,
                y: originY + (glyphBoxSize - from.y)
            )
            let toPoint = CGPoint(
                x: originX + to.x,
                y: originY + (glyphBoxSize - to.y)
            )
            path.move(to: fromPoint)
            path.line(to: toPoint)
        }

        path.lineCapStyle = .round
        path.lineWidth = glyphStrokeWidth
        color.withAlphaComponent(alpha).setStroke()
        path.stroke()
    }

    // MARK: - Overlays

    private static func drawCount(_ count: Int, color: NSColor) {
        guard count > 0 else { return }

        let text = count > 99 ? "99+" : "\(count)"
        let font = NSFont.systemFont(ofSize: 10, weight: .semibold)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]
        let attributed = NSAttributedString(string: text, attributes: attributes)
        let textSize = attributed.size()

        // Place count to the right of the glyph, vertically centered.
        let glyphRightEdge: CGFloat = 3 + glyphBoxSize
        let xOrigin = glyphRightEdge + 2
        let yOrigin = (iconSize.height - textSize.height) / 2 + 0.5
        attributed.draw(at: CGPoint(x: xOrigin, y: yOrigin))
    }

    private static func drawUrgentDot() {
        // Top-right of the glyph box. Red fill with a thin stroke so the dot
        // reads on light and dark menu bars equally.
        let dotRect = NSRect(x: 3 + glyphBoxSize - 4, y: iconSize.height - 6, width: 5, height: 5)
        NSColor(srgbRed: 0xEB/255.0, green: 0x57/255.0, blue: 0x57/255.0, alpha: 1).setFill()
        NSBezierPath(ovalIn: dotRect).fill()
    }

    private static func drawAuthMark() {
        // Small orange X in the top-right corner — re-auth required.
        let baseX: CGFloat = 3 + glyphBoxSize - 4
        let baseY: CGFloat = iconSize.height - 5
        let stroke: CGFloat = 1.3

        let path = NSBezierPath()
        path.move(to: CGPoint(x: baseX, y: baseY))
        path.line(to: CGPoint(x: baseX + 4, y: baseY + 4))
        path.move(to: CGPoint(x: baseX + 4, y: baseY))
        path.line(to: CGPoint(x: baseX, y: baseY + 4))
        path.lineCapStyle = .round
        path.lineWidth = stroke
        NSColor(srgbRed: 0xF2/255.0, green: 0x99/255.0, blue: 0x4A/255.0, alpha: 1).setStroke()
        path.stroke()
    }

    private static func drawOfflineSlash() {
        // Diagonal slash across the glyph, indicating no network.
        let originX: CGFloat = 3
        let originY: CGFloat = (iconSize.height - glyphBoxSize) / 2

        let path = NSBezierPath()
        path.move(to: CGPoint(x: originX + 1, y: originY + 1))
        path.line(to: CGPoint(x: originX + glyphBoxSize - 1, y: originY + glyphBoxSize - 1))
        path.lineCapStyle = .round
        path.lineWidth = 1.2
        NSColor.black.setStroke()
        path.stroke()
    }
}
