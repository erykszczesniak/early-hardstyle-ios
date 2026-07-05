import Foundation
import XCTest
@testable import Services

final class RecentSearchesStoreTests: XCTestCase {
    private func makeSUT(limit: Int = 8) -> UserDefaultsRecentSearchesStore {
        UserDefaultsRecentSearchesStore(key: "test.recents.\(UUID().uuidString)", limit: limit)
    }

    func test_addsMostRecentFirst_dedupedCaseInsensitively() {
        let sut = makeSUT()
        sut.add("rage")
        sut.add("defqon")
        sut.add("Rage")

        XCTAssertEqual(sut.all(), ["Rage", "defqon"])
    }

    func test_capsAtLimit() {
        let sut = makeSUT(limit: 3)
        for phrase in ["a", "b", "c", "d"] {
            sut.add(phrase)
        }
        XCTAssertEqual(sut.all(), ["d", "c", "b"])
    }

    func test_ignoresBlankPhrases() {
        let sut = makeSUT()
        sut.add("   ")
        XCTAssertTrue(sut.all().isEmpty)
    }

    func test_clear() {
        let sut = makeSUT()
        sut.add("rage")
        sut.clear()
        XCTAssertTrue(sut.all().isEmpty)
    }
}
