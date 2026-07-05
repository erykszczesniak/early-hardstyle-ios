import XCTest

/// Regression for the mini-player riding on top of the tab bar: a
/// `safeAreaInset` applied to the TabView lands at the screen edge — over the
/// bar. Docked per-tab it must sit fully ABOVE the tab bar, leaving the tab
/// buttons usable. Non-blocking in CI; run locally.
final class MiniPlayerPlacementUITest: XCTestCase {
    @MainActor
    func test_miniPlayer_sitsAboveTheTabBar() {
        let app = XCUIApplication()
        app.launchEnvironment["PROBE_VIDEO_ID"] = "GMZ2fqCFe2Q"
        app.launch()

        // Collapse the auto-opened player → mini-player docks over the tabs.
        let close = app.buttons["Close player"]
        XCTAssertTrue(close.waitForExistence(timeout: 15))
        close.tap()

        let miniPlayer = app.otherElements["mini-player"].firstMatch
        XCTAssertTrue(miniPlayer.waitForExistence(timeout: 5), "mini-player should dock after collapsing")

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists)

        XCTAssertLessThanOrEqual(
            miniPlayer.frame.maxY,
            tabBar.frame.minY + 1,
            "the mini-player must sit fully above the tab bar, not on it"
        )

        // And the tab buttons stay usable underneath it.
        let djsTab = app.tabBars.buttons["DJs"]
        XCTAssertTrue(djsTab.isHittable, "tab buttons must not be covered")
        djsTab.tap()
        XCTAssertTrue(app.navigationBars["DJs"].waitForExistence(timeout: 5))
        XCTAssertTrue(miniPlayer.exists, "the mini-player persists across tabs")
    }
}
