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
@MainActor
public final class OfficialYouTubePlayer: NSObject, PlaybackEngine, VideoSurfaceProviding, YTPlayerViewDelegate {
    public var onEvent: ((PlaybackEvent) -> Void)?

    private let playerView = YTPlayerView()
    private var cachedDuration: Double = 0
    /// The iframe API silently drops `playVideo()` while the player is still
    /// loading or the video is not yet cued — on a cold WKWebView start that
    /// window is seconds long, which used to eat both autoplay and the user's
    /// taps. So `play()` records intent, and the delegate replays it once the
    /// player reports ready/cued.
    private var pendingPlay = false
    /// Bounded warmup re-issues of `playVideo()`, reset on every fresh intent —
    /// enough to ride out a cold WKWebView, capped so a genuinely unplayable
    /// video can never spin.
    private var playRetries = 0
    private static let maxPlayRetries = 8

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
        playRetries = 0
        // `autoplay: 1` makes the iframe start playback itself the instant it is
        // ready, instead of us depending on an external `playVideo()` landing
        // during the fragile cold-WKWebView warmup window (the "several taps to
        // start" bug). The retry path below stays as a belt-and-suspenders.
        var vars: [String: Any] = [
            "playsinline": 1,
            "controls": 0,
            "rel": 0,
            "autoplay": 1
        ]
        if let seconds, seconds > 0 {
            vars["start"] = seconds
        }
        playerView.load(withVideoId: videoID, playerVars: vars)
    }

    public func play() {
        pendingPlay = true
        playRetries = 0
        attemptPlay()
    }

    public func pause() {
        pendingPlay = false
        playerView.pauseVideo()
    }

    /// Issues `playVideo()` and, while the player is still cold, keeps the
    /// intent so warmup state callbacks can re-issue it (see `didChangeTo`).
    private func attemptPlay() {
        guard pendingPlay else { return }
        playerView.playVideo()
    }

    public func seek(toFraction fraction: Double) {
        guard cachedDuration > 0 else { return }
        playerView.seek(toSeconds: Float(fraction * cachedDuration), allowSeekAhead: true)
    }

    // MARK: YTPlayerViewDelegate

    // The helper's ObjC protocol is not MainActor-annotated, so the conformances
    // are `nonisolated` and hop back — the delegate always calls on the main
    // thread (it forwards WKWebView JS callbacks).

    public nonisolated func playerViewDidBecomeReady(_: YTPlayerView) {
        MainActor.assumeIsolated {
            refreshDuration()
            onEvent?(.ready)
            // If a play intent arrived before the player was ready, honour it now.
            attemptPlay()
        }
    }

    public nonisolated func playerView(_: YTPlayerView, didChangeTo state: YTPlayerState) {
        MainActor.assumeIsolated {
            switch state {
            case .buffering:
                onEvent?(.buffering)
            case .playing:
                pendingPlay = false
                playRetries = 0
                refreshDuration()
                onEvent?(.playing)
            case .paused:
                onEvent?(.paused)
            case .ended:
                onEvent?(.ended)
            case .cued, .unstarted:
                // The player finished cueing but did not start — on a cold start
                // the earlier playVideo() was dropped. Re-issue it (bounded).
                if pendingPlay, playRetries < Self.maxPlayRetries {
                    playRetries += 1
                    attemptPlay()
                }
            default:
                break
            }
        }
    }

    public nonisolated func playerView(_: YTPlayerView, receivedError error: YTPlayerError) {
        MainActor.assumeIsolated {
            onEvent?(.failed(Self.message(for: error)))
        }
    }

    public nonisolated func playerView(_: YTPlayerView, didPlayTime playTime: Float) {
        MainActor.assumeIsolated {
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
