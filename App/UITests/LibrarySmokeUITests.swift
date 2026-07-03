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

        // The app launched into the Library.
        XCTAssertTrue(app.staticTexts["EARLYHS"].waitForExistence(timeout: 15))

        // The hero is on screen at the top of the scroll content.
        let hero = app.staticTexts["THE GOLDEN ERA"]
        XCTAssertTrue(hero.waitForExistence(timeout: 5))
        XCTAssertTrue(hero.isHittable, "hero should be visible before scrolling")

        // Scroll the grid: if a card gesture were blocking the ScrollView, the
        // content would not move and the hero would stay put.
        app.swipeUp()
        app.swipeUp()

        XCTAssertFalse(hero.isHittable, "hero should scroll off-screen — the grid must be scrollable")
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
