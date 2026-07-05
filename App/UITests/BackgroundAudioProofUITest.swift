import XCTest

/// THE background-playback proof: with the native audio engine, elapsed time
/// keeps advancing while the app is in the background (the YouTube embed
/// pauses there — that difference is the whole point of the audio engine).
/// Non-blocking in CI; run locally.
final class BackgroundAudioProofUITest: XCTestCase {
    @MainActor
    func test_nativeAudio_keepsPlayingInBackground() {
        let app = XCUIApplication()
        app.launchEnvironment["PROBE_DEMO_AUDIO"] = "1"
        app.launch()

        XCTAssertTrue(waitForPlaying(app), "the demo loop must start")
        // Let the clock move off 0:00, then sample it.
        sleep(2)
        let before = elapsedSeconds(app)

        XCUIDevice.shared.press(.home)
        sleep(8)
        app.activate()

        let after = elapsedSeconds(app)
        XCTAssertTrue(waitForPlaying(app), "still playing after returning")
        XCTAssertGreaterThanOrEqual(
            after - before, 6,
            "elapsed time must advance while backgrounded (before: \(before)s, after: \(after)s)"
        )
    }

    private func elapsedSeconds(_ app: XCUIApplication) -> Int {
        // The player shows `m:ss` as the leading time label.
        let deadline = Date().addingTimeInterval(5)
        while Date() < deadline {
            for element in app.staticTexts.allElementsBoundByIndex.prefix(30) {
                let label = element.label
                let parts = label.split(separator: ":")
                if parts.count == 2, let m = Int(parts[0]), let s = Int(parts[1]), m < 10 {
                    return m * 60 + s
                }
            }
            usleep(300_000)
        }
        return -1000
    }

    private func waitForPlaying(_ app: XCUIApplication, timeout: TimeInterval = 20) -> Bool {
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
