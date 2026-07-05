import XCTest

/// Deep-link proof: opening earlyhs://play/<id> starts real playback of that
/// set. This is the exact path widgets and App Intents ride on.
/// Non-blocking in CI; run locally.
final class DeepLinkUITest: XCTestCase {
    @MainActor
    func test_playDeepLink_startsThatSet() throws {
        let app = XCUIApplication()
        app.launch()

        let url = try XCTUnwrap(URL(string: "earlyhs://play/hh-destiny"))
        app.open(url)

        XCTAssertTrue(
            app.staticTexts["Headhunterz — Destiny"].waitForExistence(timeout: 15),
            "the deep-linked set opens in the player"
        )
        let playing = app.descendants(matching: .any)
            .matching(identifier: "player-state-playing").firstMatch
        let deadline = Date().addingTimeInterval(25)
        while Date() < deadline, !playing.exists {
            usleep(400_000)
        }
        XCTAssertTrue(playing.exists, "the deep-linked set actually plays")
    }
}
