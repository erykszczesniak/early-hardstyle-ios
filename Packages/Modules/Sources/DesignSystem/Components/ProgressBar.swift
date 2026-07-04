import SwiftUI

/// The playback progress track: a thin white track with a blue fill and an
/// optional draggable knob. When buffering, an indeterminate blue shimmer runs
/// along the track (static under Reduce Motion).
public struct ProgressBar: View {
    private let value: Double
    private let isBuffering: Bool
    private let onScrub: ((Double) -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shimmerPhase: CGFloat = -1

    public init(value: Double, isBuffering: Bool = false, onScrub: ((Double) -> Void)? = nil) {
        self.value = value
        self.isBuffering = isBuffering
        self.onScrub = onScrub
    }

    public var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let fraction = Self.clamp(value)

            ZStack(alignment: .leading) {
                Capsule().fill(Palette.textPrimary.opacity(0.1))

                if isBuffering {
                    bufferingShimmer(width: width)
                } else {
                    Capsule()
                        .fill(Palette.accentBlue)
                        .frame(width: width * fraction)
                }

                if let onScrub {
                    knob(width: width, fraction: fraction, onScrub: onScrub)
                }
            }
            .frame(height: 3)
            .frame(maxHeight: .infinity)
        }
        .frame(height: 24)
        .accessibilityElement()
        .accessibilityLabel(L10n.playbackPosition)
        .accessibilityValue(L10n.progressValue(percent: Int(Self.clamp(value) * 100)))
    }

    private func bufferingShimmer(width: CGFloat) -> some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: [.clear, Palette.accentBlueBright, .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: max(40, width * 0.3))
            .offset(x: reduceMotion ? width * 0.35 : shimmerPhase * width)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.linear(duration: 1.1).repeatForever(autoreverses: false)) {
                    shimmerPhase = 1
                }
            }
    }

    private func knob(width: CGFloat, fraction: Double, onScrub: @escaping (Double) -> Void) -> some View {
        Circle()
            .fill(Palette.textPrimary)
            .frame(width: 14, height: 14)
            .shadow(color: Palette.glowBlue, radius: 6)
            .offset(x: width * fraction - 7)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        onScrub(Self.clamp(Double(drag.location.x / max(width, 1))))
                    }
            )
    }

    /// Clamps a raw progress value into `0...1`. Pure and testable.
    /// `nonisolated` because `ProgressBar` is a `View` (main-actor isolated).
    public nonisolated static func clamp(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}
