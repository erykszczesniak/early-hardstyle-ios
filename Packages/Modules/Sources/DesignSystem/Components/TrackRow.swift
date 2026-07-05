import SwiftUI

/// A compact track row for the Tracks screen: artwork, title and meta on the
/// left, the tempo as the trailing hero. Tap opens the set.
public struct TrackRow: View {
    private let model: SetCardModel
    private let onOpen: () -> Void

    public init(model: SetCardModel, onOpen: @escaping () -> Void) {
        self.model = model
        self.onOpen = onOpen
    }

    public var body: some View {
        HStack(spacing: Spacing.md) {
            Artwork(url: model.thumbnailURL, cornerRadius: Radius.chip)
                .frame(width: 56, height: 56)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(model.title)
                    .font(Typography.cardTitle)
                    .foregroundStyle(Palette.textPrimary)
                    .lineLimit(1)
                Text(model.metaLine)
                    .font(Typography.meta)
                    .foregroundStyle(Palette.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let bpm = model.bpm {
                VStack(spacing: 0) {
                    Text(String(bpm))
                        .font(Typography.title)
                        .monospacedDigit()
                        .foregroundStyle(Palette.accentBlueBright)
                    Text(L10n.bpmCaption)
                        .font(Typography.badge)
                        .tracking(0.8)
                        .foregroundStyle(Palette.textTertiary)
                }
            }
        }
        .padding(Spacing.md)
        .cardSurface()
        .contentShape(Rectangle())
        .onTapGesture(perform: onOpen)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
        .accessibilityAddTraits(.isButton)
    }

    private var accessibilityText: String {
        var text = SetCardModel.accessibilityLabel(for: model)
        if let bpm = model.bpm {
            text += ", \(bpm) \(L10n.bpmCaption)"
        }
        return text
    }
}
