import SwiftUI

/// Presentation model for the persistent mini-player.
public struct MiniPlayerModel: Equatable, Sendable {
    public let title: String
    public let subtitle: String
    public let thumbnailURL: URL?
    public let isPlaying: Bool
    public let isSaved: Bool

    public init(title: String, subtitle: String, thumbnailURL: URL?, isPlaying: Bool, isSaved: Bool) {
        self.title = title
        self.subtitle = subtitle
        self.thumbnailURL = thumbnailURL
        self.isPlaying = isPlaying
        self.isSaved = isSaved
    }
}

/// The mini-player docked above the tab bar: 40pt artwork, title/subtitle,
/// play/pause and save. Rendered on `.ultraThinMaterial`, with the now-playing
/// pulse glow while playing.
public struct MiniPlayer: View {
    private let model: MiniPlayerModel
    private let onPlayPause: () -> Void
    private let onToggleSave: () -> Void
    private let onOpen: () -> Void

    public init(
        model: MiniPlayerModel,
        onPlayPause: @escaping () -> Void,
        onToggleSave: @escaping () -> Void,
        onOpen: @escaping () -> Void
    ) {
        self.model = model
        self.onPlayPause = onPlayPause
        self.onToggleSave = onToggleSave
        self.onOpen = onOpen
    }

    public var body: some View {
        HStack(spacing: Spacing.md) {
            Artwork(url: model.thumbnailURL, cornerRadius: Radius.chip)
                .frame(width: 40, height: 40)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(model.title)
                    .font(Typography.cardTitle)
                    .foregroundStyle(Palette.textPrimary)
                    .lineLimit(1)
                Text(model.subtitle)
                    .font(Typography.meta)
                    .foregroundStyle(Palette.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture(perform: onOpen)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(L10n.nowPlaying(title: model.title, subtitle: model.subtitle))
            .accessibilityHint(L10n.opensPlayer)
            .accessibilityAddTraits(.isButton)

            Button(action: onPlayPause) {
                Image(systemName: model.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Palette.textPrimary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(model.isPlaying ? L10n.pause : L10n.play)

            SaveHeart(isSaved: model.isSaved, action: onToggleSave)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Radius.miniPlayer, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.miniPlayer, style: .continuous)
                .strokeBorder(Palette.strokeSubtle, lineWidth: 1)
        )
        .pulseGlow(isActive: model.isPlaying)
    }
}

#Preview {
    MiniPlayer(
        model: MiniPlayerModel(
            title: "Technoboy",
            subtitle: "Sensation Black 2004",
            thumbnailURL: nil,
            isPlaying: true,
            isSaved: false
        ),
        onPlayPause: {},
        onToggleSave: {},
        onOpen: {}
    )
    .padding()
    .frame(maxHeight: .infinity)
    .screenBackground()
}
