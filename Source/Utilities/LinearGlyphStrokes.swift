import CoreGraphics

/// Single source of truth for the app's brand mark: a stylized checkmark.
/// Consumed by both the SwiftUI `LinearGlyph` shape (used in the popover
/// header and welcome views) and the AppKit `MenuBarIconRenderer` (used
/// for the menu bar status item), so both surfaces always match.
///
/// Name kept as `LinearGlyphStrokes` for call-site stability. The glyph
/// itself is no longer the Linear wordmark — it's Strategic Nerds' own
/// checkmark, so nothing links back to Linear's trademark.
enum LinearGlyphStrokes {
    /// Stroke width expressed in the same coordinate space as `endpoints`,
    /// calibrated for the 12×12 design box.
    static let strokeWidth: CGFloat = 1.9

    /// Design coordinate box.
    static let boxSize: CGFloat = 12

    /// Three corners of the checkmark polyline: (left-mid), (bottom-vertex),
    /// (top-right). Reduced from the 640-unit master design (120,340 →
    /// 260,478 → 520,160) to the 12-unit box. Callers that render with a
    /// bottom-left origin mirror y against `boxSize`.
    static let endpoints: [(CGPoint, CGPoint)] = [
        (CGPoint(x: 2.25, y: 6.4),  CGPoint(x: 4.87, y: 8.96)),
        (CGPoint(x: 4.87, y: 8.96), CGPoint(x: 9.75, y: 3.0))
    ]
}
