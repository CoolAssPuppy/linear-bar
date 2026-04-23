import CoreGraphics

/// Single source of truth for the Linear-style wordmark's geometry. Five
/// parallel diagonal strokes on a 12×12 coordinate grid, matching the Paper
/// brand mark.
///
/// Both the SwiftUI `LinearGlyph` shape (used inside the popover) and the
/// AppKit `MenuBarIconRenderer` (used for the menu bar status item) consume
/// this array, so any future brand tweak lives in exactly one place.
enum LinearGlyphStrokes {
    /// Stroke width expressed in the same 12×12 coordinate space as `endpoints`.
    static let strokeWidth: CGFloat = 1.2

    /// Design coordinate box. The glyph is drawn inside [0, boxSize] × [0, boxSize]
    /// before being scaled to the caller's frame.
    static let boxSize: CGFloat = 12

    /// Pairs of `(from, to)` endpoints describing the five parallel strokes.
    /// Top-left origin (SVG convention). Callers that render in a bottom-left
    /// origin coordinate system (e.g. NSImage) mirror y against `boxSize`.
    static let endpoints: [(CGPoint, CGPoint)] = [
        (CGPoint(x: 1.2, y: 6.4),  CGPoint(x: 5.6,  y: 10.8)),
        (CGPoint(x: 1.2, y: 3.4),  CGPoint(x: 8.6,  y: 10.8)),
        (CGPoint(x: 2.2, y: 1.2),  CGPoint(x: 10.8, y: 9.8)),
        (CGPoint(x: 5.2, y: 1.2),  CGPoint(x: 10.8, y: 6.8)),
        (CGPoint(x: 8.2, y: 1.2),  CGPoint(x: 10.8, y: 3.8))
    ]
}
