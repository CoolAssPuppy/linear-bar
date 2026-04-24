import AppKit

/// Logical states the menu bar icon can display. `MenuBarManager` maps app
/// state (unread count, auth status, reachability, sync activity) to one of
/// these, and `MenuBarIconRenderer` produces the corresponding NSImage.
enum MenuBarIconState: Hashable {
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
    /// Rendered size. 22 wide so the optional unread count has room without
    /// forcing variable-width menu bar behavior on empty states; 18 tall to
    /// match Apple's typical menu bar icon height.
    private static let iconSize = NSSize(width: 22, height: 18)

    private static let glyphBoxSize = LinearGlyphStrokes.boxSize
    private static let glyphStrokeWidth = LinearGlyphStrokes.strokeWidth

    /// NSImage instances are immutable once drawn, so caching them per state
    /// trivially avoids redrawing the same bezier on every `updateIcon()`
    /// call. `.unread(count:)` and `.urgent(count:)` vary by count, so the
    /// cache is keyed on the state value itself.
    private static var cache: [MenuBarIconState: NSImage] = [:]

    static func image(for state: MenuBarIconState) -> NSImage {
        if let cached = cache[state] { return cached }

        let image = NSImage(size: iconSize)
        image.lockFocus()
        drawContents(for: state, in: image)
        image.unlockFocus()
        cache[state] = image
        return image
    }

    private static func drawContents(for state: MenuBarIconState, in image: NSImage) {
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
    }

    // MARK: - Glyph

    private static func drawGlyph(alpha: CGFloat, color: NSColor) {
        let path = NSBezierPath()
        let originX: CGFloat = 3
        // NSImage origin is bottom-left; design space is top-left, so mirror
        // each y against `glyphBoxSize` before placing into the icon.
        let originY: CGFloat = (iconSize.height - glyphBoxSize) / 2

        for (from, to) in LinearGlyphStrokes.endpoints {
            path.move(to: CGPoint(x: originX + from.x, y: originY + (glyphBoxSize - from.y)))
            path.line(to: CGPoint(x: originX + to.x,   y: originY + (glyphBoxSize - to.y)))
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

        let xOrigin = 3 + glyphBoxSize + 2
        let yOrigin = (iconSize.height - textSize.height) / 2 + 0.5
        attributed.draw(at: CGPoint(x: xOrigin, y: yOrigin))
    }

    private static func drawUrgentDot() {
        let dotRect = NSRect(x: 3 + glyphBoxSize - 4, y: iconSize.height - 6, width: 5, height: 5)
        NSColor(srgbRed: 0xEB/255.0, green: 0x57/255.0, blue: 0x57/255.0, alpha: 1).setFill()
        NSBezierPath(ovalIn: dotRect).fill()
    }

    private static func drawAuthMark() {
        let baseX: CGFloat = 3 + glyphBoxSize - 4
        let baseY: CGFloat = iconSize.height - 5

        let path = NSBezierPath()
        path.move(to: CGPoint(x: baseX, y: baseY))
        path.line(to: CGPoint(x: baseX + 4, y: baseY + 4))
        path.move(to: CGPoint(x: baseX + 4, y: baseY))
        path.line(to: CGPoint(x: baseX, y: baseY + 4))
        path.lineCapStyle = .round
        path.lineWidth = 1.3
        NSColor(srgbRed: 0xF2/255.0, green: 0x99/255.0, blue: 0x4A/255.0, alpha: 1).setStroke()
        path.stroke()
    }

    private static func drawOfflineSlash() {
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
