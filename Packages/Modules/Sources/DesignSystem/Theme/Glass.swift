import SwiftUI

/// Liquid Glass — the app's translucent, light-bending material for floating
/// chrome (the docked mini-player, the primary action, active chips).
///
/// On iOS 26+ this is the real system Liquid Glass (`glassEffect`): it refracts
/// and reacts to whatever scrolls beneath it. On earlier systems it falls back
/// to the app's established recipe — an ultra-thin material with a hairline for
/// neutral surfaces, or a solid accent fill for tinted controls — so the design
/// reads the same everywhere, just without the live refraction.
public extension View {
    /// Clips Liquid Glass to `shape`.
    ///
    /// - Parameters:
    ///   - shape: the glass silhouette (capsule, rounded rect…).
    ///   - tint: an accent the glass takes on — used for the primary action and
    ///     active chips. `nil` keeps it neutral/clear.
    ///   - interactive: whether the glass flexes and brightens on touch. Reserve
    ///     it for controls, not passive surfaces.
    @ViewBuilder
    func liquidGlass(
        in shape: some InsettableShape,
        tint: Color? = nil,
        interactive: Bool = false
    ) -> some View {
        if #available(iOS 26.0, *) {
            glassEffect(Glass.regular.configured(tint: tint, interactive: interactive), in: shape)
        } else if let tint {
            background(tint, in: shape)
        } else {
            background(.ultraThinMaterial, in: shape)
                .overlay(shape.strokeBorder(Palette.strokeSubtle, lineWidth: 1))
        }
    }
}

/// Groups nearby Liquid Glass elements so they sample the background together
/// and can flow/merge into one another as they scroll — the "liquid" in Liquid
/// Glass. Wrap a grid or a cluster of glass cards/controls in one of these.
///
/// On iOS 26+ this is a real `GlassEffectContainer`; on earlier systems it is a
/// transparent passthrough, so callers can wrap unconditionally.
public struct GlassGroup<Content: View>: View {
    private let spacing: CGFloat?
    private let content: Content

    /// - Parameter spacing: how close two glass shapes must come before they
    ///   visually merge. `nil` uses the system default.
    public init(spacing: CGFloat? = nil, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    public var body: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: spacing) { content }
        } else {
            content
        }
    }
}

@available(iOS 26.0, *)
private extension Glass {
    /// Applies the app's optional tint/interactivity in one chained call so the
    /// call site stays a single expression.
    func configured(tint: Color?, interactive: Bool) -> Glass {
        var glass = self
        if let tint { glass = glass.tint(tint) }
        if interactive { glass = glass.interactive() }
        return glass
    }
}
