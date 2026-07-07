import SwiftUI

/// The card depth recipe: a 1px subtle border, a soft drop
/// shadow, and an inner top highlight — "flat layouts, non-flat materials".
///
/// On iOS 26+ the surface becomes Liquid Glass — a translucent panel that
/// refracts the hero mesh and artwork scrolling beneath it — while keeping the
/// same soft drop shadow for depth. On earlier systems it renders the original
/// opaque recipe, so cards look identical there.
public struct CardSurface: ViewModifier {
    var cornerRadius: CGFloat = Radius.card
    var fill: Color = Palette.elevated

    public func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .liquidGlass(in: shape)
                .shadow(color: .black.opacity(0.4), radius: 24, x: 0, y: 8)
        } else {
            content
                .background(fill, in: shape)
                .overlay(highlight)
                .overlay(border)
                .shadow(color: .black.opacity(0.4), radius: 24, x: 0, y: 8)
        }
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
