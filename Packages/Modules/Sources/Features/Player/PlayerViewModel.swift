import Core
import Foundation

/// Drives the full-screen player: owns the explicit `PlayerState` machine,
/// forwards user intent to the injected `YouTubePlayer` engine, and reflects the
/// engine's events back as state and progress. Deliberately UI-free — the view
/// layer obtains the video surface from the engine directly (see
/// `VideoSurfaceProviding`).
@MainActor
@Observable
public final class PlayerViewModel {
    /// The playback engine. Exposed so the *view* can ask it for a video
    /// surface (`VideoSurfaceProviding`); the ViewModel itself only uses the
    /// UI-free `YouTubePlayer` contract.
    public let engine: YouTubePlayer
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
        engine = player
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
        analytics.trackScreenView(.player)
        state = .loading
        engine.load(videoID: nowPlaying.youtubeID)
    }

    public func togglePlayPause() {
        if state == .playing {
            engine.pause()
        } else {
            engine.play()
        }
    }

    public func seek(toFraction fraction: Double) {
        let clamped = min(max(fraction, 0), 1)
        currentTime = clamped * duration
        engine.seek(toFraction: clamped)
    }

    public func retry() {
        start()
    }

    // MARK: Engine events

    private func handle(_ event: PlaybackEvent) {
        switch event {
        case .ready:
            // Autoplay once the video is ready.
            engine.play()
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
