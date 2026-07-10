import Foundation
import SwiftUI
import YouTubeiOSPlayerHelper

/// The production `PlaybackEngine` for YouTube sources, backed by **Google's official
/// `youtube-ios-player-helper`** (`YTPlayerView`) — the maintained wrapper
/// around the YouTube iframe player API. It performs the embedder verification
/// (origin/referer) that a hand-rolled `loadHTMLString` embed fails, which
/// surfaced as YouTube error 152 ("video unavailable") on every video.
///
/// Playback still happens inside YouTube's own embedded player — no media is
/// ripped or self-hosted, per project rules.
///
/// ## Cold-start strategy
/// A cold WKWebView (first playback after launch) takes seconds to spawn its
/// WebContent/GPU processes, and during that window the iframe API silently
/// drops `playVideo()` — and may not even deliver the state callbacks a
/// callback-driven retry would hook onto. So starting playback is belt, braces
/// AND a watchdog:
/// 1. `autoplay: 1` — the iframe starts itself the instant it is ready.
/// 2. The web view load is deferred one runloop tick so SwiftUI can mount the
///    player UI first — the tap responds instantly instead of freezing the
///    screen for the WKWebView spawn.
/// 3. A time-based watchdog re-issues `playVideo()` every 700 ms while a play
///    intent is unfulfilled (bounded to ~10 s), independent of any callback
///    arriving. `playVideo()` on an already-playing video is a no-op, so the
///    loop is harmless when racing the autoplay.
@MainActor
public final class OfficialYouTubePlayer: NSObject, PlaybackEngine, VideoSurfaceProviding, YTPlayerViewDelegate {
    public var onEvent: ((PlaybackEvent) -> Void)?

    private let playerView = YTPlayerView()
    private var cachedDuration: Double = 0
    /// True while the user (or autoplay) wants playback that has not started
    /// yet. Cleared by `.playing`, a user pause, or a player error.
    private var pendingPlay = false
    /// The watchdog re-issuing `playVideo()` while `pendingPlay` holds.
    private var playWatchdog: Task<Void, Never>?
    /// Invalidates deferred loads that were superseded by a newer `load`.
    private var loadGeneration = 0
    /// True between a `load()` call and its deferred page replacement: any
    /// delegate event arriving then comes from the SUPERSEDED video and must
    /// not reach the new track's view model.
    private var suppressStaleEvents = false

    public var surface: AnyView {
        AnyView(PlayerSurfaceView(playerView: playerView))
    }

    override public init() {
        super.init()
        // YTPlayerView holds its delegate weakly — no retain cycle
        // (the regression test asserts deallocation).
        playerView.delegate = self
        playerView.backgroundColor = .black
    }

    public func load(_ source: PlaybackSource, startAt seconds: Int?) {
        guard case let .youtube(videoID) = source else {
            onEvent?(.failed(L10n.Player.errorGeneric))
            return
        }
        cachedDuration = 0
        pendingPlay = true
        loadGeneration += 1
        let generation = loadGeneration
        // The engine is REUSED across tracks and `onEvent` is already rewired
        // to the NEW track's view model — but the OLD video's page stays alive
        // until the deferred load below replaces it. Silence its delegate
        // events (a stale `.ended` would advance the queue again and wipe the
        // new track's resume point; a stale `didPlayTime` would corrupt it)
        // and stop the old watchdog from nudging the doomed page.
        playWatchdog?.cancel()
        suppressStaleEvents = true

        var vars: [String: Any] = [
            "playsinline": 1,
            "controls": 0,
            "rel": 0,
            "autoplay": 1
        ]
        if let seconds, seconds > 0 {
            vars["start"] = seconds
        }
        // One-tick deferral: let SwiftUI commit the player UI before the
        // (potentially seconds-long, main-thread) cold WKWebView spawn runs.
        Task { @MainActor [weak self] in
            guard let self, generation == loadGeneration else { return }
            // Replacing the page tears the old one down — events from here on
            // belong to the new video.
            suppressStaleEvents = false
            playerView.load(withVideoId: videoID, playerVars: vars)
            startPlayWatchdog()
        }
    }

    public func play() {
        pendingPlay = true
        playerView.playVideo()
        startPlayWatchdog()
    }

    public func pause() {
        pendingPlay = false
        playWatchdog?.cancel()
        playerView.pauseVideo()
    }

    public func seek(toFraction fraction: Double) {
        guard cachedDuration > 0 else { return }
        playerView.seek(toSeconds: Float(fraction * cachedDuration), allowSeekAhead: true)
    }

    /// Re-issues `playVideo()` on a timer until the play intent is fulfilled.
    /// Purely time-based: a wedged/cold web view that never delivers state
    /// callbacks still gets nudged, which the callback-driven retry this
    /// replaces could not do.
    private func startPlayWatchdog() {
        playWatchdog?.cancel()
        playWatchdog = Task { @MainActor [weak self] in
            for _ in 0 ..< 15 {
                try? await Task.sleep(for: .milliseconds(700))
                guard !Task.isCancelled, let self, pendingPlay else { return }
                playerView.playVideo()
            }
        }
    }

    // MARK: YTPlayerViewDelegate

    // The helper's ObjC protocol is not MainActor-annotated, so the conformances
    // are `nonisolated` and hop back — the delegate always calls on the main
    // thread (it forwards WKWebView JS callbacks).

    public nonisolated func playerViewDidBecomeReady(_: YTPlayerView) {
        MainActor.assumeIsolated {
            guard !suppressStaleEvents else { return }
            refreshDuration()
            onEvent?(.ready)
            // If a play intent is still unfulfilled, honour it now.
            if pendingPlay {
                playerView.playVideo()
            }
        }
    }

    public nonisolated func playerView(_: YTPlayerView, didChangeTo state: YTPlayerState) {
        MainActor.assumeIsolated {
            guard !suppressStaleEvents else { return }
            switch state {
            case .buffering:
                onEvent?(.buffering)
            case .playing:
                pendingPlay = false
                playWatchdog?.cancel()
                refreshDuration()
                onEvent?(.playing)
            case .paused:
                onEvent?(.paused)
            case .ended:
                onEvent?(.ended)
            case .cued, .unstarted:
                // Finished cueing without starting — the autoplay was dropped.
                if pendingPlay {
                    playerView.playVideo()
                }
            default:
                break
            }
        }
    }

    public nonisolated func playerView(_: YTPlayerView, receivedError error: YTPlayerError) {
        MainActor.assumeIsolated {
            guard !suppressStaleEvents else { return }
            // A hard player error (unavailable, not embeddable) can't be fixed
            // by nudging — stop the watchdog so it never hammers a dead video.
            pendingPlay = false
            playWatchdog?.cancel()
            onEvent?(.failed(Self.message(for: error)))
        }
    }

    public nonisolated func playerView(_: YTPlayerView, didPlayTime playTime: Float) {
        MainActor.assumeIsolated {
            guard !suppressStaleEvents else { return }
            onEvent?(.progress(time: Double(playTime), duration: cachedDuration))
        }
    }

    // MARK: Internals

    private func refreshDuration() {
        playerView.duration { [weak self] duration, _ in
            // The completion is invoked from the web view's JS completion on the
            // main thread.
            MainActor.assumeIsolated {
                guard let self, duration > 0 else { return }
                self.cachedDuration = duration
            }
        }
    }

    /// User-facing message per player error. Pure and testable.
    nonisolated static func message(for error: YTPlayerError) -> String {
        switch error {
        case .notEmbeddable:
            L10n.Player.errorNotEmbeddable
        case .videoNotFound, .invalidParam:
            L10n.Player.errorUnavailable
        default:
            L10n.Player.errorGeneric
        }
    }
}

/// Bridges the helper's `YTPlayerView` into SwiftUI.
private struct PlayerSurfaceView: UIViewRepresentable {
    let playerView: YTPlayerView

    func makeUIView(context _: Context) -> YTPlayerView {
        playerView
    }

    func updateUIView(_: YTPlayerView, context _: Context) {}
}
