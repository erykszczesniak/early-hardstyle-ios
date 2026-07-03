import XCTest
@testable import DesignSystem

final class CardsTests: XCTestCase {
    private func makeSet(isSaved: Bool = false) -> SetCardModel {
        SetCardModel(
            id: "s1",
            title: "Showtek at Defqon.1",
            eventName: "Defqon.1",
            year: 2007,
            durationSeconds: 4125,
            genres: ["Early Hardstyle", "Reverse"],
            thumbnailURL: nil,
            isSaved: isSaved
        )
    }

    func test_setCardModel_metaLine() {
        XCTAssertEqual(makeSet().metaLine, "Defqon.1 · 2007")
    }

    func test_setCardModel_accessibilityLabel_savedAndDuration() {
        let label = SetCardModel.accessibilityLabel(for: makeSet(isSaved: true))
        XCTAssertEqual(label, "Set, Showtek at Defqon.1, Defqon.1 2007, 1 hour 8 minutes, saved")
    }

    func test_setCardModel_accessibilityLabel_notSaved() {
        let label = SetCardModel.accessibilityLabel(for: makeSet(isSaved: false))
        XCTAssertTrue(label.hasSuffix("not saved"))
    }

    func test_djCardModel_subtitle_pluralisation() {
        XCTAssertEqual(DJCardModel.subtitle(country: "Netherlands", setCount: 2), "Netherlands · 2 sets")
        XCTAssertEqual(DJCardModel.subtitle(country: "Italy", setCount: 1), "Italy · 1 set")
        XCTAssertEqual(DJCardModel.subtitle(country: "Belgium", setCount: 0), "Belgium · 0 sets")
    }

    func test_progressBar_clamp() {
        XCTAssertEqual(ProgressBar.clamp(-0.5), 0)
        XCTAssertEqual(ProgressBar.clamp(0.42), 0.42, accuracy: 0.0001)
        XCTAssertEqual(ProgressBar.clamp(1.5), 1)
    }
}
