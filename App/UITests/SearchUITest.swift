import XCTest

/// Global-search smoke: open the cover from Library, type a phrase, see
/// grouped results, open a set. Non-blocking in CI; run locally.
final class SearchUITest: XCTestCase {
    @MainActor
    func test_searchFindsAndOpensASet() {
        let app = XCUIApplication()
        app.launch()

        let searchButton = app.buttons["search-button"]
        XCTAssertTrue(searchButton.waitForExistence(timeout: 15))
        searchButton.tap()

        let field = app.textFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.typeText("rage")

        let setRow = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Rage'")).firstMatch
        XCTAssertTrue(setRow.waitForExistence(timeout: 5), "the set group lists the match")
        setRow.tap()

        XCTAssertTrue(app.buttons["Play"].waitForExistence(timeout: 5), "tapping a result opens Set Detail")
    }
}
