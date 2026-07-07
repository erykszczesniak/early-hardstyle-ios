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
        .modifier(ChipSurface(style: style))
    }

    private var foreground: Color {
        switch style {
        case .ghost: Palette.textSecondary
        case .filledBlue: Palette.textPrimary
        }
    }
}

/// The chip's surface: ghost chips are a bare hairline outline; active chips
/// ride Liquid Glass tinted electric blue.
private struct ChipSurface: ViewModifier {
    let style: Chip.Style

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: Radius.chip, style: .continuous)
    }

    func body(content: Content) -> some View {
        switch style {
        case .ghost:
            content.overlay(shape.strokeBorder(Palette.strokeSubtle, lineWidth: 1))
        case .filledBlue:
            content.liquidGlass(in: shape, tint: Palette.accentBlue)
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
