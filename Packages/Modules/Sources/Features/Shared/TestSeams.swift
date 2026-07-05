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
    /// Comma-separated `setID:seconds:duration` triples — seeds the playback
    /// progress store so resume UI can be exercised.
    static let seedProgress = "SEED_PROGRESS"
    /// When set, launches straight into the bundled demo audio loop (native
    /// audio engine) — used to prove background/lock-screen playback.
    static let probeDemoAudio = "PROBE_DEMO_AUDIO"
}
