import SwiftUI

/// A small tag/label. Ghost (stroke-only) for genres and metadata, filled-blue
/// for active/selected states.
public struct Chip: View {
    public enum Style: Sendable {
        case ghost
        case filledBlue
    }

    private let text: String
    private let style: Style
    private let systemImage: String?

    public init(_ text: String, style: Style = .ghost, systemImage: String? = nil) {
        self.text = text
        self.style = style
        self.systemImage = systemImage
    }

    public var body: some View {
        HStack(spacing: Spacing.xs) {
            if let systemImage {
                Image(systemName: systemImage)
            }
            Text(text)
        }
        .font(Typography.meta.weight(.medium))
        .lineLimit(1)
        .foregroundStyle(foreground)
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(background, in: RoundedRectangle(cornerRadius: Radius.chip, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.chip, style: .continuous)
                .strokeBorder(Palette.strokeSubtle, lineWidth: style == .ghost ? 1 : 0)
        )
    }

    private var foreground: Color {
        switch style {
        case .ghost: Palette.textSecondary
        case .filledBlue: Palette.textPrimary
        }
    }

    private var background: Color {
        switch style {
        case .ghost: .clear
        case .filledBlue: Palette.accentBlue
        }
    }
}

#Preview {
    HStack {
        Chip("Early Hardstyle")
        Chip("Reverse", style: .ghost)
        Chip("2007", style: .filledBlue, systemImage: "calendar")
    }
    .padding()
    .screenBackground()
}
