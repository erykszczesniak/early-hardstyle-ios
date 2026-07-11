import XCTest

/// Performance baselines, measured with XCTest's metrics harness (the same
/// counters Instruments reports). Run locally on demand:
///   xcodebuild test -scheme EarlyHardstyle -destination '…iPhone…' \
///     -only-testing:EarlyHardstyleUITests/PerfMetricsTests
/// The averages land in the build log and in the .xcresult; the README's
/// Performance section quotes them. Non-blocking in CI (UI tests run
/// informationally there).
final class PerfMetricsTests: XCTestCase {
    /// Cold-ish launch to a usable Library (5 iterations, averaged).
    @MainActor
    func test_launchTime() {
        let app = XCUIApplication()
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            app.launch()
        }
    }

    /// Wall-clock from process launch to REAL YouTube playback (the
    /// `player-state-playing` marker), via the DEBUG probe — the whole
    /// cold-start path this app optimises: WebKit prewarm, deferred web view
    /// load, autoplay + watchdog.
    @MainActor
    func test_launchToPlaying() {
        let app = XCUIApplication()
        app.launchEnvironment["PROBE_VIDEO_ID"] = "GMZ2fqCFe2Q"
        let playing = app.descendants(matching: .any)
            .matching(identifier: "player-state-playing").firstMatch

        measure(metrics: [XCTClockMetric()]) {
            app.launch()
            XCTAssertTrue(playing.waitForExistence(timeout: 30), "playback must start")
            app.terminate()
        }
    }

    /// App memory footprint across a browse + playback session.
    @MainActor
    func test_memoryDuringPlayback() {
        let app = XCUIApplication()
        app.launchEnvironment["PROBE_VIDEO_ID"] = "GMZ2fqCFe2Q"
        let playing = app.descendants(matching: .any)
            .matching(identifier: "player-state-playing").firstMatch

        measure(metrics: [XCTMemoryMetric(application: app)]) {
            app.launch()
            _ = playing.waitForExistence(timeout: 30)
            // Let playback and artwork settle before sampling ends.
            sleep(5)
            app.terminate()
        }
    }
}
