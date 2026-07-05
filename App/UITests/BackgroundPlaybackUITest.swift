import XCTest

/// Best-effort background-playback check: backgrounds the app mid-playback and
/// asserts the player is playing again once the app returns. (True background
/// audio can't be asserted from XCUITest — this covers the round-trip and the
/// keep-alive nudge.) Non-blocking in CI; run locally.
final class BackgroundPlaybackUITest: XCTestCase {
    @MainActor
    func test_playbackSurvivesBackgroundRoundTrip() {
        let app = XCUIApplication()
        app.launchEnvironment["PROBE_VIDEO_ID"] = "GMZ2fqCFe2Q"
        app.launch()

        XCTAssertTrue(waitForPlaying(app), "playback must start before backgrounding")

        XCUIDevice.shared.press(.home)
        sleep(4)
        app.activate()

        XCTAssertTrue(waitForPlaying(app), "playback must be running again after returning from background")
    }

    private func waitForPlaying(_ app: XCUIApplication, timeout: TimeInterval = 25) -> Bool {
        let playing = app.descendants(matching: .any)
            .matching(identifier: "player-state-playing").firstMatch
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if playing.exists { return true }
            usleep(400_000)
        }
        return playing.exists
    }
}
