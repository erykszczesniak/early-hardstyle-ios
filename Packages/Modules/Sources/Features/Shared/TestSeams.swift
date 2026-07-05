import Foundation

/// Accessibility identifiers the UI tests address. UI tests live in a separate
/// bundle, so they repeat these literals — this is the app-side single source.
enum A11yID {
    static let miniPlayer = "mini-player"

    static func playerState(_ slug: String) -> String {
        "player-state-\(slug)"
    }
}

/// Launch-environment keys for DEBUG-only test seams.
enum LaunchEnvironment {
    /// Comma-separated YouTube ids — launches straight into the player with
    /// those videos queued.
    static let probeVideoID = "PROBE_VIDEO_ID"
}
