import Core
import Foundation
import XCTest
@testable import Services

final class UserDefaultsFavouritesServiceTests: XCTestCase {
    private let suiteName = "test.favourites.suite"

    override func setUp() {
        super.setUp()
        UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    private func makeSUT(now: @escaping @Sendable () -> Date = Date.init) throws -> UserDefaultsFavouritesService {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        return UserDefaultsFavouritesService(defaults: defaults, key: "favourites", now: now)
    }

    func test_freshStore_isEmpty() async throws {
        let sut = try makeSUT()
        let ids = await sut.favouriteIDs()
        XCTAssertTrue(ids.isEmpty)
    }

    func test_toggle_persistsAcrossInstances() async throws {
        let first = try makeSUT()
        let saved = await first.toggle("set-1")
        XCTAssertTrue(saved)

        // A brand-new instance over the same store must see the saved set.
        let second = try makeSUT()
        let isFav = await second.isFavourite("set-1")
        XCTAssertTrue(isFav)
    }

    func test_toggleOff_persistsRemoval() async throws {
        let first = try makeSUT()
        await first.toggle("set-1")
        let removed = await first.toggle("set-1")
        XCTAssertFalse(removed)

        let second = try makeSUT()
        let isFav = await second.isFavourite("set-1")
        XCTAssertFalse(isFav)
    }

    func test_all_orderedNewestSavedFirst() async throws {
        let clock = TestClock()
        let sut = try makeSUT(now: clock.next)

        await sut.toggle("first")
        await sut.toggle("second")
        await sut.toggle("third")

        let all = await sut.all()
        XCTAssertEqual(all.map(\.setID), ["third", "second", "first"])
    }

    func test_favouriteIDs_reflectStoredState() async throws {
        let sut = try makeSUT()
        await sut.toggle("a")
        await sut.toggle("b")
        await sut.toggle("a") // remove a

        let ids = await sut.favouriteIDs()
        XCTAssertEqual(ids, ["b"])
    }
}

/// Monotonic clock for deterministic `savedAt` ordering.
private final class TestClock: @unchecked Sendable {
    private let lock = NSLock()
    private var seconds: TimeInterval = 0

    @Sendable func next() -> Date {
        lock.withLock {
            seconds += 1
            return Date(timeIntervalSince1970: seconds)
        }
    }
}
