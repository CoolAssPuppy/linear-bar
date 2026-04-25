import AppKit

/// Single source of truth for the app's brand glyph: a banded planet with
/// thin equatorial slats wrapping behind it. Replaces the previous
/// checkmark glyph (`LinearGlyphStrokes`). Both the AppKit
/// `MenuBarIconRenderer` and the SwiftUI `CheckmarkBrandMark` consume one
/// of the cached `NSImage`s here so the menu bar, popover header, and
/// welcome hero all render the same shape pixel-for-pixel.
///
/// Two flavors live here:
/// - `template`: monochrome, marked `isTemplate = true` so macOS inverts
///   it for dark menu bars.
/// - `branded`: the colored two-tone planet — primary `#FDB817` for the
///   front face + visible front rings, secondary `#FCDE09` for the back
///   curve and the small back-ring slivers. No background; callers wrap
///   it in their own surface.
enum PlanetGlyph {
    /// Original SVG design space. Every `boxSize` argument below is
    /// interpreted in this coordinate system before being scaled to the
    /// caller's render size.
    static let boxSize: CGFloat = 64

    /// Cache by point size + variant. NSImage is cheap to retain and
    /// expensive to rasterize from SVG, especially in the menu bar where
    /// `updateIcon()` can fire multiple times per state change.
    private static var templateCache: [Int: NSImage] = [:]
    private static var brandedCache: [Int: NSImage] = [:]

    /// Returns a square template image at `size` points. Marked
    /// `isTemplate` so macOS handles dark/light tinting.
    static func template(size: CGFloat) -> NSImage {
        let key = Int(size.rounded())
        if let cached = templateCache[key] { return cached }
        let image = renderImage(svg: Self.templateSVG, size: size)
        image.isTemplate = true
        templateCache[key] = image
        return image
    }

    /// Returns a square colored image at `size` points. Not a template —
    /// the colors are part of the brand and shouldn't be inverted.
    static func branded(size: CGFloat) -> NSImage {
        let key = Int(size.rounded())
        if let cached = brandedCache[key] { return cached }
        let image = renderImage(svg: Self.brandedSVG, size: size)
        image.isTemplate = false
        brandedCache[key] = image
        return image
    }

    private static func renderImage(svg: String, size: CGFloat) -> NSImage {
        // NSImage(data:) handles SVG natively on macOS 13+. We pin the
        // image's `size` so subsequent draw calls into a lockFocus context
        // honor the requested point size rather than the SVG's intrinsic
        // dimensions.
        guard let data = svg.data(using: .utf8),
              let image = NSImage(data: data) else {
            return NSImage(size: NSSize(width: size, height: size))
        }
        image.size = NSSize(width: size, height: size)
        return image
    }

    // MARK: - SVG sources

    /// Monochrome — every path drawn in pure black so AppKit's template
    /// machinery can recolor it. The viewBox matches `boxSize`.
    private static let templateSVG = """
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" fill="black">
      <path d="M32 4a28 28 0 0 1 0 56"/>
      <path d="M49 36a2 2 0 0 1 0-4h11a27.85 27.85 0 0 0 -.3-4h-17.7a2 2 0 0 1 0-4h8a2 2 0 0 0 0-4h-16a2 2 0 0 1 0-4h5a4 4 0 0 1 0-8h7.43a28 28 0 1 0 0 48h-5.43a2 2 0 0 1 0-4h5a2 2 0 0 0 0-4h-12a2 2 0 0 1 0-4h15a4 4 0 0 0 0-8z"/>
      <path d="M19 48a1 1 0 0 1 -1 1h-8.24a22.35 22.35 0 0 1 -1.39-2h9.63a1 1 0 0 1 1 1z"/>
      <path d="M18 33h-4a1 1 0 0 1 0-2h4a1 1 0 0 1 0 2z"/>
      <path d="M11 32a1 1 0 0 1 -1 1h-5.97c-.02-.33-.03-.66-.03-1s.01-.67.03-1h5.97a1 1 0 0 1 1 1z"/>
      <path d="M19 16a1 1 0 0 1 -1 1h-9.63a22.35 22.35 0 0 1 1.39-2h8.24a1 1 0 0 1 1 1z"/>
    </svg>
    """

    /// Two-tone — primary `#FDB817` carries the dominant front mass,
    /// secondary `#FCDE09` lights the back curve and back-ring slivers.
    private static let brandedSVG = """
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" fill="none">
      <path d="M32 4a28 28 0 0 1 0 56" fill="#FCDE09"/>
      <path d="M49 36a2 2 0 0 1 0-4h11a27.85 27.85 0 0 0 -.3-4h-17.7a2 2 0 0 1 0-4h8a2 2 0 0 0 0-4h-16a2 2 0 0 1 0-4h5a4 4 0 0 1 0-8h7.43a28 28 0 1 0 0 48h-5.43a2 2 0 0 1 0-4h5a2 2 0 0 0 0-4h-12a2 2 0 0 1 0-4h15a4 4 0 0 0 0-8z" fill="#FDB817"/>
      <g fill="#FCDE09">
        <path d="M19 48a1 1 0 0 1 -1 1h-8.24a22.35 22.35 0 0 1 -1.39-2h9.63a1 1 0 0 1 1 1z"/>
        <path d="M18 33h-4a1 1 0 0 1 0-2h4a1 1 0 0 1 0 2z"/>
        <path d="M11 32a1 1 0 0 1 -1 1h-5.97c-.02-.33-.03-.66-.03-1s.01-.67.03-1h5.97a1 1 0 0 1 1 1z"/>
        <path d="M19 16a1 1 0 0 1 -1 1h-9.63a22.35 22.35 0 0 1 1.39-2h8.24a1 1 0 0 1 1 1z"/>
      </g>
    </svg>
    """
}
