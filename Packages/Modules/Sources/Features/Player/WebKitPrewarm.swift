import WebKit

/// Spins up WebKit's out-of-process stack (WebContent/GPU/Networking) right
/// after launch, off the user's critical path. Without this, the FIRST
/// playback pays the whole cold spawn — seconds on slower machines — inside
/// the play tap, which read as "the player hangs and needs several taps".
/// All web views in a process share that stack, so the YouTube player's later
/// web view starts warm.
@MainActor
enum WebKitPrewarm {
    private static var keepAlive: WKWebView?
    private static var hasRun = false

    static func run() {
        guard !hasRun else { return }
        hasRun = true
        let webView = WKWebView(frame: .zero)
        webView.loadHTMLString("<html><body></body></html>", baseURL: nil)
        keepAlive = webView
        // The processes stay alive after the view is gone; a short grace
        // period lets the spawn finish, then the throwaway view is released.
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(15))
            keepAlive = nil
        }
    }
}
