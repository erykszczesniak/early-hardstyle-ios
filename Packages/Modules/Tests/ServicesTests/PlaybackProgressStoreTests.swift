import Core
import Foundation
import XCTest
@testable import Services

final class PlaybackProgressStoreTests: XCTestCase {
    private let suiteName = "test.progress.suite"

    override func setUp() {
        super.setUp()
        UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    private func makeSUT(now: @escaping @Sendable () -> Date = Date.init) throws -> UserDefaultsPlaybackProgressStore {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        return UserDefaultsPlaybackProgressStore(defaults: defaults, key: "progress", now: now)
    }

    func test_savesAndReadsAPosition() throws {
        let sut = try makeSUT()
        sut.save(seconds: 600, duration: 3600, for: "a")
        XCTAssertEqual(sut.position(for: "a")?.seconds, 600)
        XCTAssertEqual(sut.position(for: "a")?.fraction ?? 0, 600.0 / 3600.0, accuracy: 0.001)
    }

    func test_earlyPositions_areNotWorthRemembering() throws {
        let sut = try makeSUT()
        sut.save(seconds: 15, duration: 3600, for: "a")
        XCTAssertNil(sut.position(for: "a"))
    }

    func test_nearTheEnd_countsAsFinishedAndClears() throws {
        let sut = try makeSUT()
        sut.save(seconds: 600, duration: 3600, for: "a")
        sut.save(seconds: 3500, duration: 3600, for: "a") // > 95%
        XCTAssertNil(sut.position(for: "a"), "finished sets restart from the top")
    }

    func test_persistsAcrossInstances() throws {
        let first = try makeSUT()
        first.save(seconds: 600, duration: 3600, for: "a")

        let second = try makeSUT()
        XCTAssertEqual(second.position(for: "a")?.seconds, 600)
    }

    func test_recent_isMostRecentlyUpdatedFirst() throws {
        let clock = TestClock()
        let sut = try makeSUT(now: clock.next)
        sut.save(seconds: 100, duration: 3600, for: "first")
        sut.save(seconds: 100, duration: 3600, for: "second")
        sut.save(seconds: 100, duration: 3600, for: "third")

        XCTAssertEqual(sut.recent(limit: 2).map(\.id), ["third", "second"])
    }

    func test_clear_removesTheEntry() throws {
        let sut = try makeSUT()
        sut.save(seconds: 600, duration: 3600, for: "a")
        sut.clear(for: "a")
        XCTAssertNil(sut.position(for: "a"))
    }
}

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
