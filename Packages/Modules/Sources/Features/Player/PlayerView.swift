import DesignSystem
import SwiftUI

/// The full-screen player: the embedded YouTube surface, metadata, a seekable
/// progress track, transport controls and first-class buffering/error/ended
/// states. Playback is via the official YouTube player (attribution required).
public struct PlayerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: PlayerViewModel

    public init(viewModel: PlayerViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        VStack(spacing: Spacing.xl) {
            header
            media
            metadata
            progressSection
            controls
            Spacer(minLength: 0)
            attribution
        }
        .padding(Spacing.gutter)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .screenBackground()
        .foregroundStyle(Palette.textPrimary)
        .task { viewModel.start() }
    }

    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Close player")
            Spacer()
        }
    }

    private var media: some View {
        viewModel.surface
            .aspectRatio(16.0 / 9.0, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .strokeBorder(Palette.strokeSubtle, lineWidth: 1)
            )
    }

    private var metadata: some View {
        VStack(spacing: Spacing.xs) {
            Text(viewModel.nowPlaying.title)
                .font(Typography.title)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            Text(viewModel.nowPlaying.subtitle)
                .font(Typography.meta)
                .foregroundStyle(Palette.textSecondary)
        }
    }

    @ViewBuilder
    private var progressSection: some View {
        if case let .failed(message) = viewModel.state {
            ErrorInline(message: message) { viewModel.retry() }
        } else {
            VStack(spacing: Spacing.xs) {
                ProgressBar(
                    value: viewModel.progress,
                    isBuffering: viewModel.isBuffering,
                    onScrub: viewModel.canScrub ? { viewModel.seek(toFraction: $0) } : nil
                )
                HStack {
                    Text(viewModel.currentTimeText)
                    Spacer()
                    Text(viewModel.durationText)
                }
                .font(Typography.meta)
                .foregroundStyle(Palette.textSecondary)
            }
        }
    }

    private var controls: some View {
        HStack(spacing: Spacing.xxl) {
            transportButton(system: "backward.fill", size: 28) {}
                .disabled(true)
                .opacity(0.35)

            Button { viewModel.togglePlayPause() } label: {
                Image(systemName: primaryGlyph)
                    .font(.system(size: 30, weight: .heavy))
                    .foregroundStyle(.black)
                    .frame(width: 72, height: 72)
                    .background(Palette.textPrimary, in: Circle())
            }
            .accessibilityLabel(playPauseLabel)

            transportButton(system: "forward.fill", size: 28) {}
                .disabled(true)
                .opacity(0.35)
        }
    }

    private func transportButton(system: String, size: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.system(size: size, weight: .semibold))
                .foregroundStyle(Palette.textPrimary)
                .frame(width: 44, height: 44)
        }
    }

    private var attribution: some View {
        Text("Video played via the official YouTube player")
            .font(Typography.meta)
            .foregroundStyle(Palette.textTertiary)
            .multilineTextAlignment(.center)
    }

    private var primaryGlyph: String {
        switch viewModel.state {
        case .ended: "arrow.clockwise"
        case .playing: "pause.fill"
        default: "play.fill"
        }
    }

    private var playPauseLabel: String {
        switch viewModel.state {
        case .ended: "Replay"
        case .playing: "Pause"
        default: "Play"
        }
    }
}
