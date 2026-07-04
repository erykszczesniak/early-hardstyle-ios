import Foundation
import SwiftUI
import WebKit

/// The production `YouTubePlayer`, backed by the **official YouTube iframe
/// player API** in a `WKWebView`. No media is ripped or self-hosted — playback
/// happens inside YouTube's own embedded player, per project rules.
///
/// State and progress flow Swift-ward via a script message handler; commands
/// flow JS-ward via `evaluateJavaScript`.
@MainActor
public final class WebKitYouTubePlayer: NSObject, YouTubePlayer, WKScriptMessageHandler, WKNavigationDelegate {
    public var onEvent: ((PlaybackEvent) -> Void)?

    public let webView: WKWebView

    public var surface: AnyView {
        AnyView(YouTubeWebView(webView: webView))
    }

    override public init() {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        let controller = WKUserContentController()
        configuration.userContentController = controller
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.isScrollEnabled = false
        super.init()
        webView.navigationDelegate = self
        // A WKUserContentController retains its script-message handler STRONGLY.
        // Registering `self` directly would form a retain cycle
        // (self → webView → configuration → controller → self), so the engine
        // and its WKWebView would never deallocate when the player closes.
        // Register a weak proxy instead so the cycle is broken.
        controller.add(ScriptMessageProxy(self), name: "yt")
    }

    public func load(videoID: String) {
        let html = Self.playerHTML.replacingOccurrences(of: "__VIDEO_ID__", with: videoID)
        webView.loadHTMLString(html, baseURL: URL(string: "https://www.youtube.com"))
    }

    public func play() {
        webView.evaluateJavaScript("player && player.playVideo();")
    }

    public func pause() {
        webView.evaluateJavaScript("player && player.pauseVideo();")
    }

    public func seek(toFraction fraction: Double) {
        webView.evaluateJavaScript("seekToFraction(\(fraction));")
    }

    // MARK: WKScriptMessageHandler

    public func userContentController(
        _: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard let body = message.body as? [String: Any], let type = body["type"] as? String else { return }
        switch type {
        case "ready": onEvent?(.ready)
        case "buffering": onEvent?(.buffering)
        case "playing": onEvent?(.playing)
        case "paused": onEvent?(.paused)
        case "ended": onEvent?(.ended)
        case "failed": onEvent?(.failed(body["message"] as? String ?? "Playback failed."))
        case "progress":
            let time = body["time"] as? Double ?? 0
            let duration = body["duration"] as? Double ?? 0
            onEvent?(.progress(time: time, duration: duration))
        default:
            break
        }
    }

    // MARK: WKNavigationDelegate

    // Delegate signatures use WKNavigation! (Apple API); the IUO is unavoidable.
    // swiftlint:disable implicitly_unwrapped_optional

    public func webView(_: WKWebView, didFail _: WKNavigation!, withError _: Error) {
        onEvent?(.failed("Couldn't load the player. Check your connection and try again."))
    }

    public func webView(
        _: WKWebView,
        didFailProvisionalNavigation _: WKNavigation!,
        withError _: Error
    ) {
        onEvent?(.failed("Couldn't load the player. Check your connection and try again."))
    }

    // swiftlint:enable implicitly_unwrapped_optional

    // MARK: Embedded page

    private static let playerHTML = """
    <!DOCTYPE html>
    <html>
    <head>
      <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
      <style>
        html, body { margin: 0; background: #000; height: 100%; overflow: hidden; }
        #player { width: 100%; height: 100%; }
      </style>
    </head>
    <body>
      <div id="player"></div>
      <script>
        var player;
        function post(payload) { window.webkit.messageHandlers.yt.postMessage(payload); }
        function seekToFraction(f) { if (player) { player.seekTo(player.getDuration() * f, true); } }
        var tag = document.createElement('script');
        tag.src = "https://www.youtube.com/iframe_api";
        document.body.appendChild(tag);
        function onYouTubeIframeAPIReady() {
          player = new YT.Player('player', {
            videoId: '__VIDEO_ID__',
            host: 'https://www.youtube.com',
            playerVars: {
              playsinline: 1, controls: 0, rel: 0, modestbranding: 1,
              enablejsapi: 1, origin: 'https://www.youtube.com'
            },
            events: {
              onReady: function() {
                post({ type: 'ready' });
                setInterval(function() {
                  if (player && player.getDuration) {
                    post({ type: 'progress', time: player.getCurrentTime(), duration: player.getDuration() });
                  }
                }, 500);
              },
              onStateChange: function(e) {
                switch (e.data) {
                  case YT.PlayerState.BUFFERING: post({ type: 'buffering' }); break;
                  case YT.PlayerState.PLAYING: post({ type: 'playing' }); break;
                  case YT.PlayerState.PAUSED: post({ type: 'paused' }); break;
                  case YT.PlayerState.ENDED: post({ type: 'ended' }); break;
                  default: break;
                }
              },
              onError: function(e) {
                post({ type: 'failed', message: 'This video cannot be played (code ' + e.data + ').' });
              }
            }
          });
        }
      </script>
    </body>
    </html>
    """
}

/// Weak forwarder so a `WKUserContentController` can reference the real script
/// message handler without retaining it — the fix for the engine retain cycle.
@MainActor
private final class ScriptMessageProxy: NSObject, WKScriptMessageHandler {
    private weak var target: WKScriptMessageHandler?

    init(_ target: WKScriptMessageHandler) {
        self.target = target
    }

    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        target?.userContentController(controller, didReceive: message)
    }
}

/// Bridges the engine's `WKWebView` into SwiftUI.
struct YouTubeWebView: UIViewRepresentable {
    let webView: WKWebView

    func makeUIView(context _: Context) -> WKWebView {
        webView
    }

    func updateUIView(_: WKWebView, context _: Context) {}
}
