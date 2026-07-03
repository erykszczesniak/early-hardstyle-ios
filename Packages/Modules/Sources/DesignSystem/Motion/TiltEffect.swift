import SwiftUI

/// The signature card interaction: press-and-drag tilts the card in 3D (max
/// ~6° on each axis) with a subtle scale, springing back on release. Degrades
/// to a plain scale under Reduce Motion.
public struct TiltEffect: ViewModifier {
    /// Nominal half-extent used to normalise drag translation into an angle.
    /// Avoids a per-cell GeometryReader while giving a natural feel.
    private let reference: CGFloat = 120
    private let maxAngle: Double = 6

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @GestureState private var translation: CGSize = .zero
    @State private var isPressed = false

    public func body(content: Content) -> some View {
        content
            .rotation3DEffect(
                .degrees(reduceMotion ? 0 : angle(for: translation.height, invert: true)),
                axis: (x: 1, y: 0, z: 0),
                perspective: 0.6
            )
            .rotation3DEffect(
                .degrees(reduceMotion ? 0 : angle(for: translation.width, invert: false)),
                axis: (x: 0, y: 1, z: 0),
                perspective: 0.6
            )
            .scaleEffect(isPressed ? 1.02 : 1)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: translation)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isPressed)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .updating($translation) { value, state, _ in
                        state = value.translation
                    }
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
    }

    private func angle(for offset: CGFloat, invert: Bool) -> Double {
        let normalised = Double(max(-reference, min(reference, offset)) / reference)
        let angle = normalised * maxAngle
        return invert ? -angle : angle
    }
}

public extension View {
    /// Applies the signature tilt-on-press interaction (Reduce-Motion aware).
    func tiltable() -> some View {
        modifier(TiltEffect())
    }
}
