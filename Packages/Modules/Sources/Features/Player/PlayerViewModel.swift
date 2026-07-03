import Core
import Foundation
import SwiftUI

/// Drives the full-screen player: owns the explicit `PlayerState` machine,
/// forwards user intent to the injected `YouTubePlayer` engine, and reflects the
/// engine's events back as state and progress.
@MainActor
@Observable
public final class PlayerViewModel {
    private let player: YouTubePlayer
    private let analytics: any Analytics

    public let nowPlaying: NowPlaying

    public private(set) var state: PlayerState = .idle
    public private(set) var currentTime: Double = 0
    public private(set) var duration: Double = 0

    /// Invoked when playback reaches the end — the queue uses this to autoplay
    /// the next item.
    public var onPlaybackEnded: (() -> Void)?

    public init(nowPlaying: NowPlaying, player: YouTubePlayer, analytics: any Analytics) {
        self.nowPlaying = nowPlaying
        self.player = player
        self.analytics = analytics
        player.onEvent = { [weak self] event in
            self?.handle(event)
        }
    }

    // MARK: Derived UI values

    public var isPlaying: Bool {
        state == .playing
    }

    public var canScrub: Bool {
        duration > 0
    }

    /// The engine's video surface, embedded by the Player screen.
    public var surface: AnyView {
        player.surface
    }

    public var progress: Double {
        guard duration > 0 else { return 0 }
        return min(max(currentTime / duration, 0), 1)
    }

    public var isBuffering: Bool {
        state == .buffering || state == .loading
    }

    public var currentTimeText: String {
        HardstyleSet.formatDuration(seconds: Int(currentTime))
    }

    public var durationText: String {
        HardstyleSet.formatDuration(seconds: Int(duration))
    }

    // MARK: Intent

    public func start() {
        analytics.trackScreenView("Player")
        state = .loading
        player.load(videoID: nowPlaying.youtubeID)
    }

    public func togglePlayPause() {
        if state == .playing {
            player.pause()
        } else {
            player.play()
        }
    }

    public func seek(toFraction fraction: Double) {
        let clamped = min(max(fraction, 0), 1)
        currentTime = clamped * duration
        player.seek(toFraction: clamped)
    }

    public func retry() {
        start()
    }

    // MARK: Engine events

    private func handle(_ event: PlaybackEvent) {
        switch event {
        case .ready:
            // Autoplay once the video is ready.
            player.play()
        case .buffering:
            state = .buffering
        case .playing:
            state = .playing
        case .paused:
            state = .paused
        case .ended:
            state = .ended
            onPlaybackEnded?()
        case let .failed(message):
            state = .failed(message: message)
        case let .progress(time, total):
            currentTime = time
            duration = total
        }
    }
}
