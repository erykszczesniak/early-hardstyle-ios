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

        // The player screen must open IMMEDIATELY on the first tap — the cold
        // WKWebView spawn must never run before the UI responds (the "app
        // hangs on Play" regression).
        let close = app.buttons["Close player"].firstMatch
        XCTAssertTrue(close.waitForExistence(timeout: 2.5), "player must open right away on the first tap")

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
