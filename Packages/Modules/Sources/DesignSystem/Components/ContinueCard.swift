import SwiftUI

/// A compact rail card for resuming a set: artwork with a thin progress bar
/// underneath, then title and meta. Tap resumes playback.
public struct ContinueCard: View {
    private let model: SetCardModel
    private let fraction: Double
    private let onOpen: () -> Void

    public init(model: SetCardModel, fraction: Double, onOpen: @escaping () -> Void) {
        self.model = model
        self.fraction = fraction
        self.onOpen = onOpen
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Artwork(url: model.thumbnailURL, cornerRadius: Radius.chip)
                .frame(width: 148, height: 83)
                .accessibilityHidden(true)

            ProgressBar(value: fraction)
                .frame(width: 148)

            Text(model.title)
                .font(Typography.meta.weight(.semibold))
                .foregroundStyle(Palette.textPrimary)
                .lineLimit(1)
            Text(model.metaLine)
                .font(Typography.badge)
                .foregroundStyle(Palette.textSecondary)
                .lineLimit(1)
        }
        .frame(width: 148)
        .contentShape(Rectangle())
        .onTapGesture(perform: onOpen)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(SetCardModel.accessibilityLabel(for: model))
        .accessibilityAddTraits(.isButton)
    }
}
