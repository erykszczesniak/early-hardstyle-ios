import Core
import Foundation
import XCTest
@testable import Services

final class FavouritesServiceTests: XCTestCase {
    func test_toggle_addsThenRemoves() async {
        let sut = InMemoryFavouritesService()

        let addedState = await sut.toggle("set-1")
        XCTAssertTrue(addedState)
        var isFav = await sut.isFavourite("set-1")
        XCTAssertTrue(isFav)

        let removedState = await sut.toggle("set-1")
        XCTAssertFalse(removedState)
        isFav = await sut.isFavourite("set-1")
        XCTAssertFalse(isFav)
    }

    func test_favouriteIDs_reflectsCurrentState() async {
        let sut = InMemoryFavouritesService()
        await sut.toggle("a")
        await sut.toggle("b")
        await sut.toggle("a") // remove a

        let ids = await sut.favouriteIDs()
        XCTAssertEqual(ids, ["b"])
    }

    func test_seed_isRespected() async {
        let seed = [Favourite(setID: "x", savedAt: Date(timeIntervalSince1970: 100))]
        let sut = InMemoryFavouritesService(seed: seed)

        let isFav = await sut.isFavourite("x")
        XCTAssertTrue(isFav)
    }

    func test_all_isSortedNewestFirst() async {
        // Deterministic clock: each toggle stamps an increasing date.
        let counter = TickingClock(start: 0)
        let sut = InMemoryFavouritesService(now: counter.next)

        await sut.toggle("first")
        await sut.toggle("second")
        await sut.toggle("third")

        let all = await sut.all()
        XCTAssertEqual(all.map(\.setID), ["third", "second", "first"])
    }
}

/// A `Sendable` monotonically-increasing clock for deterministic `savedAt`
/// ordering in tests.
private final class TickingClock: @unchecked Sendable {
    private let lock = NSLock()
    private var seconds: TimeInterval

    init(start: TimeInterval) {
        seconds = start
    }

    @Sendable func next() -> Date {
        lock.withLock {
            seconds += 1
            return Date(timeIntervalSince1970: seconds)
        }
    }
}
