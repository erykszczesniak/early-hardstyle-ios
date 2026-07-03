import SwiftUI

/// The Home hero's living texture: an animated mesh of deep blues on black,
/// drifting very slowly. Uses `MeshGradient` on iOS 18+, and falls back to a
/// static radial gradient on earlier systems or under Reduce Motion.
public struct HeroMesh: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init() {}

    public var body: some View {
        if #available(iOS 18, *), !reduceMotion {
            TimelineView(.animation(minimumInterval: 1.0 / 20.0)) { context in
                mesh(phase: context.date.timeIntervalSinceReferenceDate)
            }
        } else if #available(iOS 18, *) {
            mesh(phase: 0)
        } else {
            fallback
        }
    }

    @available(iOS 18, *)
    private func mesh(phase: TimeInterval) -> some View {
        // Very slow drift (~60s loop) of the interior control point.
        let drift = sin(phase * (2 * .pi / 60))
        let dx = Float(0.5 + 0.12 * drift)
        let dy = Float(0.5 + 0.10 * cos(phase * (2 * .pi / 60)))

        return MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0, 0], [0.5, 0], [1, 0],
                [0, 0.5], [dx, dy], [1, 0.5],
                [0, 1], [0.5, 1], [1, 1]
            ],
            colors: [
                Palette.base, Palette.base, Palette.base,
                Palette.accentBlueDeep, Palette.accentBlue, Palette.accentBlueDeep,
                Palette.base, Palette.accentBlueDeep, Palette.base
            ]
        )
    }

    private var fallback: some View {
        RadialGradient(
            colors: [Palette.accentBlueDeep, Palette.base],
            center: .center,
            startRadius: 10,
            endRadius: 400
        )
        .background(Palette.base)
    }
}

#Preview {
    HeroMesh()
        .frame(height: 300)
        .ignoresSafeArea()
}
