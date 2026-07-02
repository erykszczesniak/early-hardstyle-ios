import SwiftUI

/// The card depth recipe from `the design spec`: a 1px subtle border, a soft drop
/// shadow, and an inner top highlight — "flat layouts, non-flat materials".
public struct CardSurface: ViewModifier {
    var cornerRadius: CGFloat = Radius.card
    var fill: Color = Palette.elevated

    public func body(content: Content) -> some View {
        content
            .background(fill, in: shape)
            .overlay(highlight)
            .overlay(border)
            .shadow(color: .black.opacity(0.4), radius: 24, x: 0, y: 8)
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }

    private var highlight: some View {
        shape
            .fill(
                LinearGradient(
                    stops: [
                        .init(color: Palette.innerHighlight, location: 0),
                        .init(color: .clear, location: 0.2)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .allowsHitTesting(false)
    }

    private var border: some View {
        shape.strokeBorder(Palette.strokeSubtle, lineWidth: 1)
    }
}

public extension View {
    /// Applies the standard card depth (border + shadow + inner highlight).
    func cardSurface(cornerRadius: CGFloat = Radius.card, fill: Color = Palette.elevated) -> some View {
        modifier(CardSurface(cornerRadius: cornerRadius, fill: fill))
    }

    /// Fills the whole screen (including safe-area) with the app background.
    func screenBackground() -> some View {
        background(Palette.base.ignoresSafeArea())
    }
}
