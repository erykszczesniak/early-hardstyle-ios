import Foundation
import SwiftUI
import YouTubeiOSPlayerHelper

/// The production `YouTubePlayer`, backed by **Google's official
/// `youtube-ios-player-helper`** (`YTPlayerView`) — the maintained wrapper
/// around the YouTube iframe player API. It performs the embedder verification
/// (origin/referer) that a hand-rolled `loadHTMLString` embed fails, which
/// surfaced as YouTube error 152 ("video unavailable") on every video.
///
/// Playback still happens inside YouTube's own embedded player — no media is
/// ripped or self-hosted, per project rules.
@MainActor
public final class OfficialYouTubePlayer: NSObject, YouTubePlayer, VideoSurfaceProviding, YTPlayerViewDelegate {
    public var onEvent: ((PlaybackEvent) -> Void)?

    private let playerView = YTPlayerView()
    private var cachedDuration: Double = 0

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

    public func load(videoID: String, startAt seconds: Int?) {
        cachedDuration = 0
        var vars: [String: Any] = [
            "playsinline": 1,
            "controls": 0,
            "rel": 0
        ]
        if let seconds, seconds > 0 {
            vars["start"] = seconds
        }
        playerView.load(withVideoId: videoID, playerVars: vars)
    }

    public func play() {
        playerView.playVideo()
    }

    public func pause() {
        playerView.pauseVideo()
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
        }
    }

    public nonisolated func playerView(_: YTPlayerView, didChangeTo state: YTPlayerState) {
        MainActor.assumeIsolated {
            switch state {
            case .buffering:
                onEvent?(.buffering)
            case .playing:
                refreshDuration()
                onEvent?(.playing)
            case .paused:
                onEvent?(.paused)
            case .ended:
                onEvent?(.ended)
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
