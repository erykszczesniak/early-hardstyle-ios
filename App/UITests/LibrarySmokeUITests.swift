import XCTest

/// End-to-end smoke tests that exercise real touch interaction — the gap that
/// let a scroll-blocking gesture ship. The scroll assertion specifically guards
/// against a card gesture swallowing the ScrollView's pan.
final class LibrarySmokeUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    @MainActor
    func test_libraryLaunchesAndScrolls() {
        let app = XCUIApplication()
        app.launch()

        // The app launched into the Library with seed content.
        XCTAssertTrue(app.staticTexts["EARLYHS"].waitForExistence(timeout: 20))
        let scroll = app.scrollViews.firstMatch
        XCTAssertTrue(scroll.waitForExistence(timeout: 10))

        // A set near the bottom of the grid — a LazyVGrid only renders it once
        // scrolled near, so if a card gesture were blocking the ScrollView it
        // would never appear. Scrolling until it becomes hittable is robust
        // against swipe-distance differences between the simulator and CI.
        let deepCard = app.buttons.matching(NSPredicate(format: "label CONTAINS 'A-lusion'")).firstMatch
        var attempts = 0
        while !deepCard.isHittable, attempts < 15 {
            scroll.swipeUp()
            attempts += 1
        }

        XCTAssertTrue(deepCard.isHittable, "scrolling must reveal sets below the fold — the grid must be scrollable")
    }

    @MainActor
    func test_openingSetOpensDetailWithPlay() {
        let app = XCUIApplication()
        app.launch()

        // Tap the first set card (a combined "Set, …" accessibility button).
        let card = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Set,'")).firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 15))
        card.tap()

        // Set Detail exposes a full-width Play entry point.
        XCTAssertTrue(app.buttons["Play"].waitForExistence(timeout: 5), "tapping a card should open Set Detail")
    }

    @MainActor
    func test_tabsSwitch() {
        let app = XCUIApplication()
        app.launch()

        app.tabBars.buttons["DJs"].tap()
        XCTAssertTrue(app.navigationBars["DJs"].waitForExistence(timeout: 5))

        app.tabBars.buttons["Saved"].tap()
        XCTAssertTrue(app.navigationBars["Saved"].waitForExistence(timeout: 5))

        app.tabBars.buttons["Library"].tap()
        XCTAssertTrue(app.staticTexts["EARLYHS"].waitForExistence(timeout: 5))
    }
}
