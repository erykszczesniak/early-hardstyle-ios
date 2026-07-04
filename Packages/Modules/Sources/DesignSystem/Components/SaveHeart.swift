import SwiftUI

/// The save (favourite) control. Tapping flips the heart 180° on the y-axis and
/// lands filled-blue (DESIGN.md motion #6). Under Reduce Motion it simply
/// toggles fill with no flip. Meets the 44pt hit target.
public struct SaveHeart: View {
    private let isSaved: Bool
    private let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(isSaved: Bool, action: @escaping () -> Void) {
        self.isSaved = isSaved
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: isSaved ? "heart.fill" : "heart")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(isSaved ? Palette.accentBlue : Palette.textPrimary)
                .frame(width: 44, height: 44)
                .background(Palette.scrimSoft, in: Circle())
                .rotation3DEffect(
                    .degrees(reduceMotion ? 0 : (isSaved ? 180 : 0)),
                    axis: (x: 0, y: 1, z: 0)
                )
                .animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.7), value: isSaved)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isSaved ? L10n.saved : L10n.save)
        .accessibilityAddTraits(isSaved ? [.isSelected] : [])
    }
}
