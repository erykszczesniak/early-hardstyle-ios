import DesignSystem
import SwiftUI

/// The full-screen player: the embedded YouTube surface, metadata, a seekable
/// progress track, transport controls (with queue prev/next) and first-class
/// buffering/error/ended states. Bound to the app-level `PlaybackController` so
/// it and the mini-player reflect one playback session.
public struct PlayerView: View {
    @Bindable private var controller: PlaybackController
    @State private var showQueue = false

    public init(controller: PlaybackController) {
        self.controller = controller
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
        .sheet(isPresented: $showQueue) {
            QueueView(controller: controller)
                .presentationDetents([.medium, .large])
        }
        .overlay(alignment: .topLeading) { stateMarker }
    }

    /// An invisible marker whose identifier tracks the player state, so UI
    /// tests can assert on real playback (e.g. `player-state-playing`).
    private var stateMarker: some View {
        Color.clear
            .frame(width: 1, height: 1)
            .accessibilityElement()
            .accessibilityIdentifier("player-state-\(stateSlug)")
    }

    private var stateSlug: String {
        switch controller.current?.state {
        case .playing: "playing"
        case .buffering: "buffering"
        case .paused: "paused"
        case .ended: "ended"
        case .loading: "loading"
        case .failed: "failed"
        case .idle, nil: "idle"
        }
    }

    private var header: some View {
        HStack {
            Button { controller.collapse() } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel(L10n.Player.close)
            Spacer()
            Button { showQueue = true } label: {
                Image(systemName: "list.bullet")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel(L10n.Player.queue)
        }
    }

    @ViewBuilder
    private var media: some View {
        // The surface is a view-layer concern: engines that render video conform
        // to VideoSurfaceProviding; the ViewModel's engine contract stays UI-free.
        if let provider = controller.current?.engine as? VideoSurfaceProviding {
            provider.surface
                .aspectRatio(16.0 / 9.0, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                        .strokeBorder(Palette.strokeSubtle, lineWidth: 1)
                )
        }
    }

    private var metadata: some View {
        VStack(spacing: Spacing.xs) {
            Text(controller.nowPlaying?.title ?? "")
                .font(Typography.title)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            Text(controller.nowPlaying?.subtitle ?? "")
                .font(Typography.meta)
                .foregroundStyle(Palette.textSecondary)
        }
    }

    @ViewBuilder
    private var progressSection: some View {
        if let current = controller.current {
            if case let .failed(message) = current.state {
                ErrorInline(message: message) { current.retry() }
            } else {
                VStack(spacing: Spacing.xs) {
                    ProgressBar(
                        value: current.progress,
                        isBuffering: current.isBuffering,
                        onScrub: current.canScrub ? { current.seek(toFraction: $0) } : nil
                    )
                    HStack {
                        Text(current.currentTimeText)
                        Spacer()
                        Text(current.durationText)
                    }
                    .font(Typography.meta)
                    .foregroundStyle(Palette.textSecondary)
                }
            }
        }
    }

    private var controls: some View {
        HStack(spacing: Spacing.xxl) {
            transportButton(system: "backward.fill", size: 28) { controller.goPrevious() }
                .disabled(!controller.canGoPrevious)
                .opacity(controller.canGoPrevious ? 1 : 0.35)
                .accessibilityLabel(L10n.Player.previous)

            Button { controller.togglePlayPause() } label: {
                Image(systemName: primaryGlyph)
                    .font(.system(size: 30, weight: .heavy))
                    .foregroundStyle(.black)
                    .frame(width: 72, height: 72)
                    .background(Palette.textPrimary, in: Circle())
            }
            .accessibilityLabel(playPauseLabel)

            transportButton(system: "forward.fill", size: 28) { controller.advance() }
                .disabled(!controller.canGoNext)
                .opacity(controller.canGoNext ? 1 : 0.35)
                .accessibilityLabel(L10n.Player.next)
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
        Text(L10n.Player.attribution)
            .font(Typography.meta)
            .foregroundStyle(Palette.textTertiary)
            .multilineTextAlignment(.center)
    }

    private var primaryGlyph: String {
        switch controller.current?.state {
        case .ended: "arrow.clockwise"
        case .playing: "pause.fill"
        default: "play.fill"
        }
    }

    private var playPauseLabel: String {
        switch controller.current?.state {
        case .ended: L10n.Player.replay
        case .playing: L10n.Player.pause
        default: L10n.Player.play
        }
    }
}
