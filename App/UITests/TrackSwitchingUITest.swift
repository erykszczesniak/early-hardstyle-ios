import XCTest

/// End-to-end proof that switching tracks actually switches the video: the
/// regression was a per-track engine whose web view never joined the view
/// hierarchy, so the old video kept showing (and sounding) after Next.
/// Non-blocking in CI (UI tests run informationally there); run locally.
final class TrackSwitchingUITest: XCTestCase {
    private let firstID = "GMZ2fqCFe2Q" // Headhunterz — The Home of Hardstyle
    private let secondID = "d5YuAzUbqe8" // Headhunterz — HARD with STYLE #01

    @MainActor
    func test_nextTrack_startsPlayingTheNextVideo() {
        let app = XCUIApplication()
        app.launchEnvironment["PROBE_VIDEO_ID"] = "\(firstID),\(secondID)"
        app.launch()

        // First track reaches real playback.
        XCTAssertTrue(waitForPlaying(app), "first track must reach playing")
        XCTAssertTrue(app.staticTexts[firstID].exists, "player shows the first track")

        // Next → the title flips AND the player returns to real playback for
        // the new video (the old bug kept the first video playing forever).
        app.buttons["Next"].tap()
        XCTAssertTrue(app.staticTexts[secondID].waitForExistence(timeout: 5), "title switches to the next track")
        XCTAssertTrue(waitForPlaying(app), "the NEXT video must reach playing — not just the label")

        // And back.
        app.buttons["Previous"].tap()
        XCTAssertTrue(app.staticTexts[firstID].waitForExistence(timeout: 5))
        XCTAssertTrue(waitForPlaying(app), "the previous video must reach playing again")
    }

    /// Waits for the `player-state-playing` marker, tolerating the
    /// loading/buffering states in between.
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
