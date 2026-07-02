import Core
import SwiftUI

/// A year badge — black chip with white uppercase numerals. Sits top-left on
/// set artwork.
public struct YearBadge: View {
    private let year: Int

    public init(_ year: Int) {
        self.year = year
    }

    public var body: some View {
        Text(String(year))
            .font(Typography.badge)
            .tracking(0.4)
            .foregroundStyle(Palette.textPrimary)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(.black.opacity(0.55), in: Capsule())
            .accessibilityLabel("Year \(year)")
    }
}

/// A duration badge — compact runtime label with a clock glyph. Sits
/// bottom-right on set artwork.
public struct DurationBadge: View {
    private let seconds: Int

    public init(seconds: Int) {
        self.seconds = seconds
    }

    public var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "clock")
            Text(HardstyleSet.formatDuration(seconds: seconds))
        }
        .font(Typography.badge)
        .foregroundStyle(Palette.textPrimary)
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(.black.opacity(0.55), in: Capsule())
        .accessibilityLabel(Self.accessibleDuration(seconds: seconds))
    }

    /// Spoken duration, e.g. "1 hour 8 minutes". Exposed for reuse by cards.
    /// `nonisolated` because it is pure — callable from any isolation domain.
    public nonisolated static func accessibleDuration(seconds: Int) -> String {
        let clamped = max(0, seconds)
        let hours = clamped / 3600
        let minutes = (clamped % 3600) / 60
        var parts: [String] = []
        if hours > 0 { parts.append("\(hours) hour\(hours == 1 ? "" : "s")") }
        if minutes > 0 { parts.append("\(minutes) minute\(minutes == 1 ? "" : "s")") }
        if parts.isEmpty { parts.append("\(clamped) second\(clamped == 1 ? "" : "s")") }
        return parts.joined(separator: " ")
    }
}

#Preview {
    HStack {
        YearBadge(2007)
        DurationBadge(seconds: 4125)
    }
    .padding()
    .screenBackground()
}
