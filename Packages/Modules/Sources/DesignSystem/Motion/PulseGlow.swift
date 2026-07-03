import SwiftUI

/// The "now playing" pulse: a slow (2s) breathing blue glow with a subtle
/// 1.00→1.01 scale, communicating active playback. Under Reduce Motion the glow
/// is present but static (no breathing, no scale).
public struct PulseGlow: ViewModifier {
    private let isActive: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulsing = false

    public init(isActive: Bool) {
        self.isActive = isActive
    }

    public func body(content: Content) -> some View {
        content
            .scaleEffect(animating ? 1.01 : 1)
            .shadow(color: Palette.glowBlue, radius: glowRadius)
            .animation(breathing, value: pulsing)
            .onAppear { pulsing = isActive }
            .onChange(of: isActive) { _, active in pulsing = active }
    }

    private var animating: Bool {
        isActive && pulsing && !reduceMotion
    }

    private var glowRadius: CGFloat {
        guard isActive else { return 0 }
        if reduceMotion { return 12 }
        return pulsing ? 18 : 8
    }

    private var breathing: Animation? {
        guard isActive, !reduceMotion else { return nil }
        return .easeInOut(duration: 2).repeatForever(autoreverses: true)
    }
}

public extension View {
    /// Adds the now-playing pulse glow when `isActive` (Reduce-Motion aware).
    func pulseGlow(isActive: Bool) -> some View {
        modifier(PulseGlow(isActive: isActive))
    }
}
