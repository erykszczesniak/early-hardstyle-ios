import Foundation
import MediaPlayer

// swiftformat:disable redundantSelf

/// Publishes the current track to the system Now Playing surfaces (lock
/// screen, Control Center) and routes remote commands (headphones, lock-screen
/// transport) back into the playback controller. Fully effective for the
/// native audio engine; harmless for the YouTube embed (which the system
/// suspends in the background anyway).
@MainActor
final class NowPlayingCenter {
    private var artworkTask: Task<Void, Never>?

    func attach(to controller: PlaybackController) {
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.addTarget { [weak controller] _ in
            controller?.togglePlayPause()
            return .success
        }
        center.pauseCommand.addTarget { [weak controller] _ in
            controller?.togglePlayPause()
            return .success
        }
        center.nextTrackCommand.addTarget { [weak controller] _ in
            guard let controller, controller.canGoNext else { return .noSuchContent }
            controller.advance()
            return .success
        }
        center.previousTrackCommand.addTarget { [weak controller] _ in
            guard let controller, controller.canGoPrevious else { return .noSuchContent }
            controller.goPrevious()
            return .success
        }
        center.changePlaybackPositionCommand.addTarget { [weak controller] event in
            guard let controller,
                  let event = event as? MPChangePlaybackPositionCommandEvent,
                  let current = controller.current,
                  current.duration > 0 else { return .commandFailed }
            current.seek(toFraction: event.positionTime / current.duration)
            return .success
        }
    }

    /// Publishes static track metadata (and kicks off an artwork fetch).
    func update(with nowPlaying: NowPlaying) {
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: nowPlaying.title,
            MPMediaItemPropertyArtist: nowPlaying.subtitle
        ]
        info[MPNowPlayingInfoPropertyPlaybackRate] = 1.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info

        artworkTask?.cancel()
        guard let url = nowPlaying.artworkURL else { return }
        artworkTask = Task { [weak self] in
            guard let (data, _) = try? await URLSession.shared.data(from: url),
                  let image = UIImage(data: data), !Task.isCancelled else { return }
            self?.mergeArtwork(image)
        }
    }

    /// Refreshes the dynamic fields on each progress tick.
    func updateProgress(time: Double, duration: Double, isPlaying: Bool) {
        var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = time
        info[MPMediaItemPropertyPlaybackDuration] = duration
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    func clear() {
        artworkTask?.cancel()
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    private func mergeArtwork(_ image: UIImage) {
        // MediaPlayer invokes the request handler on ITS OWN queue — the
        // closure must be @Sendable/nonisolated or the Swift 6 isolation
        // assertion traps (found by the deep-link UI test). UIImage is
        // immutable here and safe to read across threads.
        nonisolated(unsafe) let captured = image
        var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
        info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { @Sendable _ in captured }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
}
