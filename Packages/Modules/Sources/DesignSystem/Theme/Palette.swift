import SwiftUI

extension Color {
    /// Builds a colour from a packed `0xRRGGBB` value. Internal to DesignSystem
    /// so hex literals never appear elsewhere in the app.
    init(hex: UInt32, opacity: Double = 1) {
        let red = Double((hex >> 16) & 0xFF) / 255
        let green = Double((hex >> 8) & 0xFF) / 255
        let blue = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
}

/// The app's colour tokens — the single source of truth for colour.
///
/// Brand direction (see `DESIGN.md`): black canvas, blue energy. Electric blue
/// is the ONLY accent; states are expressed with blue intensity + white
/// opacity. No second hue is ever introduced.
public enum Palette {
    /// App background — near-black, slightly blue-tinted.
    public static let base = Color(hex: 0x0A0A0C)
    /// Cards and sheets.
    public static let elevated = Color(hex: 0x121216)
    /// Nested surfaces and chips.
    public static let elevated2 = Color(hex: 0x1A1A20)

    /// THE accent: active tab, play states, progress, links.
    public static let accentBlue = Color(hex: 0x3B82F6)
    /// Glows, gradient hot end, "now playing" pulse. Use for text-sized blue
    /// (passes contrast on `base`).
    public static let accentBlueBright = Color(hex: 0x60A5FA)
    /// Pressed states, gradient cold end.
    public static let accentBlueDeep = Color(hex: 0x1D4ED8)

    /// Headings and titles.
    public static let textPrimary = Color.white
    /// Metadata (event, year, duration).
    public static let textSecondary = Color(hex: 0x9CA3AF)
    /// Hints and placeholders.
    public static let textTertiary = Color(hex: 0x5B616E)

    /// 1px card borders.
    public static let strokeSubtle = Color.white.opacity(0.06)
    /// Soft outer glow on active/playing elements.
    public static let glowBlue = Color(hex: 0x3B82F6).opacity(0.30)

    /// Inner top highlight applied over card surfaces.
    public static let innerHighlight = Color.white.opacity(0.04)
}
