import XCTest

/// End-to-end playback smoke test: launches straight into the player (via the
/// DEBUG `PROBE_VIDEO_ID` seam) and asserts the engine reaches real `playing`
/// state. This is the proof that the official YouTube embed actually plays —
/// the regression that shipped previously was "every video shows error 152".
/// Non-blocking in CI (UI tests run informationally there); run locally.
final class PlaybackSmokeUITest: XCTestCase {
    @MainActor
    func test_playbackReachesPlaying() {
        let app = XCUIApplication()
        app.launchEnvironment["PROBE_VIDEO_ID"] = "GMZ2fqCFe2Q" // Headhunterz — The Home of Hardstyle
        app.launch()

        let playing = app.descendants(matching: .any)
            .matching(identifier: "player-state-playing").firstMatch
        let failed = app.descendants(matching: .any)
            .matching(identifier: "player-state-failed").firstMatch

        // Wait up to 30s for a definitive outcome.
        let deadline = Date().addingTimeInterval(30)
        while Date() < deadline {
            if playing.exists { break }
            if failed.exists { break }
            usleep(500_000)
        }

        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "playback-smoke"
        shot.lifetime = .keepAlways
        add(shot)

        XCTAssertTrue(playing.exists, "the player must reach real playing state (not error/buffering forever)")
    }
}
