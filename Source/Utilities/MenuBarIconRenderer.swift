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
    /// Standard menu bar icon height. The width adapts per state — see
    /// `iconSize(for:)` — so multi-digit unread counts don't clip.
    private static let iconHeight: CGFloat = 18

    /// Visible glyph size inside the icon. Independent of total width so
    /// the planet stays consistent across states.
    private static let glyphBoxSize: CGFloat = 12

    /// Padding to the left of the glyph and to the right of the count.
    private static let glyphLeftPadding: CGFloat = 3
    private static let glyphCountGap: CGFloat = 2
    private static let trailingPadding: CGFloat = 3

    private static let countFont = NSFont.systemFont(ofSize: 10, weight: .semibold)

    /// NSImage instances are immutable once drawn, so caching them per state
    /// trivially avoids redrawing the same bezier on every `updateIcon()`
    /// call. `.unread(count:)` and `.urgent(count:)` vary by count, so the
    /// cache is keyed on the state value itself.
    private static var cache: [MenuBarIconState: NSImage] = [:]

    static func image(for state: MenuBarIconState) -> NSImage {
        if let cached = cache[state] { return cached }

        let size = iconSize(for: state)
        let image = NSImage(size: size)
        image.lockFocus()
        drawContents(for: state, in: image, size: size)
        image.unlockFocus()
        cache[state] = image
        return image
    }

    /// Width grows for states that include a count so "23" or "99+"
    /// fits without clipping. States without a count stay at the
    /// glyph-only width so the menu bar doesn't reserve empty space.
    private static func iconSize(for state: MenuBarIconState) -> NSSize {
        let baseWidth = glyphLeftPadding + glyphBoxSize + trailingPadding

        let count: Int
        switch state {
        case .unread(let n), .urgent(let n): count = n
        default: count = 0
        }

        guard count > 0 else {
            return NSSize(width: baseWidth, height: iconHeight)
        }

        let text = count > 99 ? "99+" : "\(count)"
        let textWidth = (text as NSString)
            .size(withAttributes: [.font: countFont])
            .width
        let totalWidth = glyphLeftPadding + glyphBoxSize + glyphCountGap + ceil(textWidth) + trailingPadding
        return NSSize(width: totalWidth, height: iconHeight)
    }

    private static func drawContents(for state: MenuBarIconState, in image: NSImage, size: NSSize) {
        let context = NSGraphicsContext.current?.cgContext
        context?.saveGState()
        defer { context?.restoreGState() }

        switch state {
        case .quiet:
            drawGlyph(alpha: 1, color: .black, in: size)
            image.isTemplate = true
        case .unread(let count):
            drawGlyph(alpha: 1, color: .black, in: size)
            drawCount(count, color: .black, in: size)
            image.isTemplate = true
        case .urgent(let count):
            let urgentColor = NSColor(srgbRed: 0xED/255.0, green: 0xEF/255.0, blue: 0xF7/255.0, alpha: 1)
            drawGlyph(alpha: 1, color: urgentColor, in: size)
            drawCount(count, color: urgentColor, in: size)
            drawUrgentDot(in: size)
            image.isTemplate = false
        case .syncing:
            drawGlyph(alpha: 0.55, color: .black, in: size)
            image.isTemplate = true
        case .needsAuth:
            drawGlyph(alpha: 1, color: NSColor(srgbRed: 0x5E/255.0, green: 0x60/255.0, blue: 0x76/255.0, alpha: 1), in: size)
            drawAuthMark(in: size)
            image.isTemplate = false
        case .offline:
            drawGlyph(alpha: 1, color: .black, in: size)
            drawOfflineSlash(in: size)
            image.isTemplate = true
        }
    }

    // MARK: - Glyph

    private static func drawGlyph(alpha: CGFloat, color: NSColor, in size: NSSize) {
        let originY: CGFloat = (size.height - glyphBoxSize) / 2
        let rect = NSRect(x: glyphLeftPadding, y: originY, width: glyphBoxSize, height: glyphBoxSize)

        // The PlanetGlyph image is a black-filled SVG (template). When the
        // outer image is itself a template (set by the caller for .quiet,
        // .unread, .syncing, .offline) macOS handles tinting in the menu
        // bar. For non-template states (.urgent, .needsAuth) we tint here
        // by drawing the image masked to the requested color.
        let glyph = PlanetGlyph.template(size: glyphBoxSize)

        if color == .black {
            glyph.draw(in: rect, from: .zero, operation: .sourceOver, fraction: alpha)
        } else {
            // Tint by filling the rect through the glyph's alpha. Avoids
            // creating a per-call colored copy of the image.
            color.setFill()
            rect.fill()
            glyph.draw(in: rect, from: .zero, operation: .destinationIn, fraction: alpha)
        }
    }

    // MARK: - Overlays

    private static func drawCount(_ count: Int, color: NSColor, in size: NSSize) {
        guard count > 0 else { return }

        let text = count > 99 ? "99+" : "\(count)"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: countFont,
            .foregroundColor: color
        ]
        let attributed = NSAttributedString(string: text, attributes: attributes)
        let textSize = attributed.size()

        let xOrigin = glyphLeftPadding + glyphBoxSize + glyphCountGap
        let yOrigin = (size.height - textSize.height) / 2 + 0.5
        attributed.draw(at: CGPoint(x: xOrigin, y: yOrigin))
    }

    private static func drawUrgentDot(in size: NSSize) {
        let dotRect = NSRect(x: glyphLeftPadding + glyphBoxSize - 4, y: size.height - 6, width: 5, height: 5)
        NSColor(srgbRed: 0xEB/255.0, green: 0x57/255.0, blue: 0x57/255.0, alpha: 1).setFill()
        NSBezierPath(ovalIn: dotRect).fill()
    }

    private static func drawAuthMark(in size: NSSize) {
        let baseX: CGFloat = glyphLeftPadding + glyphBoxSize - 4
        let baseY: CGFloat = size.height - 5

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

    private static func drawOfflineSlash(in size: NSSize) {
        let originY: CGFloat = (size.height - glyphBoxSize) / 2

        let path = NSBezierPath()
        path.move(to: CGPoint(x: glyphLeftPadding + 1, y: originY + 1))
        path.line(to: CGPoint(x: glyphLeftPadding + glyphBoxSize - 1, y: originY + glyphBoxSize - 1))
        path.lineCapStyle = .round
        path.lineWidth = 1.2
        NSColor.black.setStroke()
        path.stroke()
    }
}
