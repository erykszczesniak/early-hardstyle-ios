import XCTest

/// End-to-end proof for the second half of the reported bug: tapping a row in
/// the QUEUE must actually switch playback to that track (not just highlight
/// it). Non-blocking in CI; run locally.
final class QueueJumpUITest: XCTestCase {
    private let firstID = "GMZ2fqCFe2Q"
    private let secondID = "d5YuAzUbqe8"

    @MainActor
    func test_tappingAQueueRow_switchesPlaybackToThatTrack() {
        let app = XCUIApplication()
        app.launchEnvironment["PROBE_VIDEO_ID"] = "\(firstID),\(secondID)"
        app.launch()

        XCTAssertTrue(waitForPlaying(app), "first track must reach playing")

        // Open the queue and jump to the second track.
        app.buttons["Queue"].tap()
        let secondRow = app.buttons.matching(
            NSPredicate(format: "label CONTAINS %@", secondID)
        ).firstMatch
        XCTAssertTrue(secondRow.waitForExistence(timeout: 5), "queue lists the second track")
        secondRow.tap()
        app.buttons["Done"].tap()

        // The player is now on the second track AND actually playing it.
        XCTAssertTrue(app.staticTexts[secondID].waitForExistence(timeout: 5), "player shows the tapped track")
        XCTAssertTrue(waitForPlaying(app), "the tapped track must reach real playing state")
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
