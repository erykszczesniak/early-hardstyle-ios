import XCTest

/// Walks every screen and captures the README screenshots as attachments.
/// Regenerate with:
///   xcodebuild test -only-testing:EarlyHardstyleUITests/ScreenshotTourUITests \
///     -resultBundlePath tour.xcresult ...
///   xcrun xcresulttool export attachments --path tour.xcresult --output-path shots/
/// Non-blocking in CI; run locally on a booted simulator.
final class ScreenshotTourUITests: XCTestCase {
    @MainActor
    func test_captureReadmeScreenshots() {
        let app = XCUIApplication()
        // Mid-set progress on two long sets so the resume rail renders.
        app.launchEnvironment["SEED_PROGRESS"] = "hh-home:1440:3720,hh-hws:820:3600"
        app.launch()

        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 15))
        settle(4) // thumbnails
        shoot(app, "library")

        // Populate Saved for the later shot.
        let saves = app.buttons.matching(NSPredicate(format: "label == 'Save'"))
        if saves.count > 1 {
            saves.element(boundBy: 0).tap()
            saves.element(boundBy: 1).tap()
        }

        app.buttons["search-button"].tap()
        let field = app.textFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.typeText("head\n") // commit so the keyboard drops and groups show
        settle(2)
        shoot(app, "search")
        app.buttons["Cancel"].tap()

        app.tabBars.buttons["Tracks"].tap()
        settle(2)
        shoot(app, "tracks")

        app.tabBars.buttons["DJs"].tap()
        settle(4) // avatars
        shoot(app, "djs")

        app.tabBars.buttons["Library"].tap()
        let card = app.buttons
            .matching(NSPredicate(format: "label CONTAINS 'Headhunterz'"))
            .firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        card.tap()
        settle(3)
        shoot(app, "set-detail")

        app.buttons["Play"].firstMatch.tap()
        let playing = app.descendants(matching: .any)
            .matching(identifier: "player-state-playing").firstMatch
        XCTAssertTrue(playing.waitForExistence(timeout: 30), "player reaches playing")
        settle(3) // let the video frame render
        shoot(app, "player")

        app.buttons["Close player"].tap()
        app.tabBars.buttons["Saved"].tap()
        settle(3)
        shoot(app, "saved")
    }

    @MainActor
    private func shoot(_ app: XCUIApplication, _ name: String) {
        _ = app // keeps the call site uniform; the capture is whole-screen
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func settle(_ seconds: UInt32) {
        sleep(seconds)
    }
}
