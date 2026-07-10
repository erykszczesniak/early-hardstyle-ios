import Core
import Foundation
import Services
import XCTest
@testable import Features

@MainActor
final class LibraryViewModelTests: XCTestCase {
    // MARK: Fixtures

    private func makeCatalog() -> Catalog {
        Catalog(
            djs: [
                Dj(id: "showtek", name: "Showtek", country: "Netherlands"),
                Dj(id: "technoboy", name: "Technoboy", country: "Italy")
            ],
            events: [Event(id: "defqon-1", name: "Defqon.1", country: "Netherlands")],
            genres: [Genre(id: "early", name: "Early Hardstyle")],
            sets: [
                makeSet(id: "a", title: "Showtek 2005", djID: "showtek", year: 2005, seconds: 3600),
                makeSet(id: "b", title: "Technoboy 2007", djID: "technoboy", year: 2007, seconds: 4125)
            ]
        )
    }

    private func makeSet(id: String, title: String, djID: String, year: Int, seconds: Int) -> HardstyleSet {
        HardstyleSet(
            id: id,
            title: title,
            djID: djID,
            eventID: "defqon-1",
            year: year,
            durationSeconds: seconds,
            youtubeID: id,
            genreIDs: ["early"]
        )
    }

    private func makeSUT(
        catalog: CatalogService,
        favourites: FavouritesService = InMemoryFavouritesService(),
        progress: PlaybackProgressStoring = SpyProgressStore(),
        analytics: SpyAnalytics = SpyAnalytics()
    ) -> LibraryViewModel {
        LibraryViewModel(
            catalog: catalog,
            favourites: FavouritesStore(service: favourites),
            progress: progress,
            recents: UserDefaultsRecentSearchesStore(key: "test.recents.\(UUID().uuidString)"),
            analytics: analytics
        )
    }

    // MARK: Loading

    func test_load_success_populatesNewestFirst() async {
        let sut = makeSUT(catalog: MockCatalogService.returning(makeCatalog()))

        await sut.load()

        XCTAssertEqual(sut.state, .loaded)
        XCTAssertEqual(sut.visibleSets.map(\.id), ["b", "a"])
        XCTAssertEqual(sut.latestSet?.id, "b")
    }

    func test_load_emptyCatalog_yieldsEmptyState() async {
        let sut = makeSUT(catalog: MockCatalogService.returning(.empty))

        await sut.load()

        XCTAssertEqual(sut.state, .empty)
        XCTAssertTrue(sut.visibleSets.isEmpty)
    }

    func test_load_failure_yieldsRetryableError() async {
        let sut = makeSUT(catalog: MockCatalogService.failing(.offline))

        await sut.load()

        guard case let .failed(message, retryable) = sut.state else {
            return XCTFail("Expected failed state, got \(sut.state)")
        }
        XCTAssertFalse(message.isEmpty)
        XCTAssertTrue(retryable)
    }

    func test_load_decodingFailure_isNotRetryable() async {
        let sut = makeSUT(catalog: MockCatalogService.failing(.decodingFailed("bad")))

        await sut.load()

        guard case let .failed(_, retryable) = sut.state else {
            return XCTFail("Expected failed state")
        }
        XCTAssertFalse(retryable)
    }

    func test_retry_afterFailure_recovers() async {
        let sut = makeSUT(catalog: FlakyCatalogService(failFirst: 1, then: makeCatalog()))

        await sut.load()
        guard case .failed = sut.state else {
            return XCTFail("Expected first load to fail")
        }

        await sut.retry()
        XCTAssertEqual(sut.state, .loaded)
        XCTAssertEqual(sut.visibleSets.count, 2)
    }

    // MARK: Favourites

    func test_toggleSave_marksSetSavedAndPersists() async {
        let favourites = InMemoryFavouritesService()
        let sut = makeSUT(catalog: MockCatalogService.returning(makeCatalog()), favourites: favourites)
        await sut.load()

        await sut.toggleSave("b")

        XCTAssertEqual(sut.visibleSets.first { $0.id == "b" }?.isSaved, true)
        let stored = await favourites.isFavourite("b")
        XCTAssertTrue(stored)
    }

    func test_load_reflectsPreexistingFavourites() async {
        let favourites = InMemoryFavouritesService(seed: [Favourite(setID: "a", savedAt: Date())])
        let sut = makeSUT(catalog: MockCatalogService.returning(makeCatalog()), favourites: favourites)

        await sut.load()

        XCTAssertEqual(sut.visibleSets.first { $0.id == "a" }?.isSaved, true)
        XCTAssertEqual(sut.visibleSets.first { $0.id == "b" }?.isSaved, false)
    }

    // MARK: Filters

    func test_filterOptions_derivedAfterLoad() async {
        let sut = makeSUT(catalog: MockCatalogService.returning(makeCatalog()))
        await sut.load()

        XCTAssertEqual(sut.filterOptions.years, [2007, 2005])
        XCTAssertEqual(sut.filterOptions.countries, ["Italy", "Netherlands"])
    }

    func test_filter_narrowsVisibleSets() async {
        let sut = makeSUT(catalog: MockCatalogService.returning(makeCatalog()))
        await sut.load()

        sut.filter.years = [2007]
        XCTAssertEqual(sut.visibleSets.map(\.id), ["b"])
        XCTAssertEqual(sut.activeFilterCount, 1)
    }

    func test_filterHidingEverything_reportsNoResults() async {
        let sut = makeSUT(catalog: MockCatalogService.returning(makeCatalog()))
        await sut.load()

        sut.filter.countries = ["Germany"] // matches nothing in the fixture
        XCTAssertTrue(sut.visibleSets.isEmpty)
        XCTAssertTrue(sut.hasNoResults)
    }

    func test_clearFilters_restoresAllSets() async {
        let sut = makeSUT(catalog: MockCatalogService.returning(makeCatalog()))
        await sut.load()
        sut.filter.years = [2007]
        XCTAssertEqual(sut.visibleSets.count, 1)

        sut.clearFilters()
        XCTAssertEqual(sut.visibleSets.count, 2)
        XCTAssertFalse(sut.isRefining)
    }

    // MARK: Jump back in

    func test_jumpBackIn_mapsRecentsToLoadedSets() async {
        let progress = SpyProgressStore()
        progress.save(seconds: 600, duration: 3600, for: "a")
        progress.save(seconds: 300, duration: 3600, for: "ghost") // not in catalogue
        let sut = makeSUT(catalog: MockCatalogService.returning(makeCatalog()), progress: progress)
        await sut.load()

        let rail = sut.jumpBackIn
        XCTAssertEqual(rail.map(\.card.id), ["a"], "unknown ids are skipped")
        XCTAssertEqual(rail.first?.fraction ?? 0, 600.0 / 3600.0, accuracy: 0.001)
        XCTAssertEqual(rail.first?.nowPlaying.setID, "a")
    }

    func test_jumpBackIn_isEmptyWithoutProgress() async {
        let sut = makeSUT(catalog: MockCatalogService.returning(makeCatalog()))
        await sut.load()
        XCTAssertTrue(sut.jumpBackIn.isEmpty)
    }

    func test_heroSet_isNewestWithoutProgress() async {
        let sut = makeSUT(catalog: MockCatalogService.returning(makeCatalog()))
        await sut.load()
        XCTAssertEqual(sut.heroSet?.id, sut.latestSet?.id, "no listening history -> newest set")
        XCTAssertEqual(sut.heroSet?.id, "b", "newest (2007) set leads the catalogue")
        XCTAssertFalse(sut.heroResumes, "fresh catalogue -> 'Play latest' label")
    }

    func test_heroSet_isMostRecentlyPlayedWhenProgressExists() async {
        let progress = SpyProgressStore()
        progress.save(seconds: 600, duration: 3600, for: "a")
        let sut = makeSUT(catalog: MockCatalogService.returning(makeCatalog()), progress: progress)
        await sut.load()
        XCTAssertEqual(sut.heroSet?.id, "a", "the hero continues the last-played set")
        XCTAssertTrue(sut.heroResumes, "listening history -> 'Continue listening' label")
    }

    func test_refreshProgress_revealsEntriesSavedAfterLoad() async {
        let progress = SpyProgressStore()
        let sut = makeSUT(catalog: MockCatalogService.returning(makeCatalog()), progress: progress)
        await sut.load()
        XCTAssertTrue(sut.jumpBackIn.isEmpty)

        // Playback saves progress outside the ViewModel; a refresh nudge must
        // surface it on the rail (and retarget the hero) without a reload.
        progress.save(seconds: 600, duration: 3600, for: "a")
        sut.refreshProgress()

        XCTAssertEqual(sut.jumpBackIn.map(\.card.id), ["a"])
        XCTAssertEqual(sut.heroSet?.id, "a")
    }

    func test_resumeQueue_startsWithResumedSetAndAppendsRelated() async {
        let progress = SpyProgressStore()
        progress.save(seconds: 600, duration: 3600, for: "a")
        let sut = makeSUT(catalog: MockCatalogService.returning(makeCatalog()), progress: progress)
        await sut.load()

        guard let entry = sut.jumpBackIn.first else { return XCTFail("expected a resume entry") }
        let queue = sut.resumeQueue(for: entry)

        XCTAssertEqual(queue.first?.setID, "a", "the resumed set plays first")
        XCTAssertGreaterThan(queue.count, 1, "related sets follow so next/previous work")
        XCTAssertTrue(queue.dropFirst().contains { $0.setID == "b" })
    }

    // MARK: Analytics

    func test_onAppear_tracksScreenViewAndLoads() async {
        let analytics = SpyAnalytics()
        let sut = makeSUT(catalog: MockCatalogService.returning(makeCatalog()), analytics: analytics)

        await sut.onAppear()

        XCTAssertEqual(sut.state, .loaded)
        XCTAssertTrue(analytics.events.contains(.screenView("Library")))
    }
}

/// Catalogue service that fails the first `failFirst` attempts, then succeeds —
/// used to exercise retry/recovery.
final class FlakyCatalogService: CatalogService, @unchecked Sendable {
    private let lock = NSLock()
    private var attempts = 0
    private let failFirst: Int
    private let catalog: Catalog

    init(failFirst: Int, then catalog: Catalog) {
        self.failFirst = failFirst
        self.catalog = catalog
    }

    func loadCatalog() async throws -> Catalog {
        let attempt = lock.withLock {
            attempts += 1
            return attempts
        }
        if attempt <= failFirst { throw CatalogError.timedOut }
        return catalog
    }
}

/// Thread-safe analytics spy for Feature tests.
final class SpyAnalytics: Analytics, @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [AnalyticsEvent] = []

    var events: [AnalyticsEvent] {
        lock.withLock { storage }
    }

    func track(_ event: AnalyticsEvent) {
        lock.withLock { storage.append(event) }
    }
}
