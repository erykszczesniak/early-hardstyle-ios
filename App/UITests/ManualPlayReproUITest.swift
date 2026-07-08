import XCTest

/// End-to-end proof of the real user flow (not the DEBUG probe seam): a fresh
/// launch, "Play latest" in the hero, then Set Detail's Play must reach real
/// playback on the FIRST tap. Guards the regression where a cold WKWebView
/// needed several taps before the video started. Non-blocking in CI; run
/// locally.
final class ManualPlayReproUITest: XCTestCase {
    @MainActor
    func test_playLatest_thenPlay_reachesPlayingOnFirstTap() {
        let app = XCUIApplication()
        app.launch()

        app.buttons["Play latest"].firstMatch.tap()

        // Set Detail's primary Play.
        let play = app.buttons["Play"].firstMatch
        XCTAssertTrue(play.waitForExistence(timeout: 5), "Set Detail Play button")
        play.tap()

        let playing = app.descendants(matching: .any)
            .matching(identifier: "player-state-playing").firstMatch
        let failed = app.descendants(matching: .any)
            .matching(identifier: "player-state-failed").firstMatch

        let deadline = Date().addingTimeInterval(20)
        while Date() < deadline {
            if playing.exists || failed.exists { break }
            usleep(400_000)
        }
        add(XCTAttachment(screenshot: app.screenshot()))
        XCTAssertTrue(playing.exists, "must reach playing on the first Play tap (failed=\(failed.exists))")
    }
}
