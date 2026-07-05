import Core
import Foundation
import Services
import XCTest
@testable import Features

@MainActor
final class TracksViewModelTests: XCTestCase {
    private func catalog() -> Catalog {
        Catalog(
            djs: [Dj(id: "showtek", name: "Showtek", country: "Netherlands")],
            events: [Event(id: "defqon-1", name: "Defqon.1", country: "Netherlands")],
            genres: [],
            sets: [
                makeSet(id: "slow", title: "B slow", year: 2003, bpm: 140),
                makeSet(id: "fast", title: "C fast", year: 2005, bpm: 150),
                makeSet(id: "mid", title: "A mid", year: 2007, bpm: 145),
                makeSet(id: "none", title: "D none", year: 2006, bpm: nil)
            ]
        )
    }

    private func makeSet(id: String, title: String, year: Int, bpm: Int?) -> HardstyleSet {
        HardstyleSet(
            id: id,
            title: title,
            djID: "showtek",
            eventID: "defqon-1",
            year: year,
            durationSeconds: 3600,
            youtubeID: id,
            bpm: bpm
        )
    }

    private func makeSUT(catalog service: CatalogService) -> TracksViewModel {
        TracksViewModel(
            catalog: service,
            favourites: FavouritesStore(service: InMemoryFavouritesService()),
            analytics: SpyAnalytics()
        )
    }

    func test_defaultSort_isBPMHardestFirst_unknownLast() async {
        let sut = makeSUT(catalog: MockCatalogService.returning(catalog()))
        await sut.load()

        XCTAssertEqual(sut.sort, .bpm)
        XCTAssertEqual(sut.tracks.map(\.id), ["fast", "mid", "slow", "none"])
        XCTAssertEqual(sut.tracks.first?.bpm, 150)
    }

    func test_sortNewest_byYearDescending() async {
        let sut = makeSUT(catalog: MockCatalogService.returning(catalog()))
        await sut.load()

        sut.sort = .newest
        XCTAssertEqual(sut.tracks.map(\.id), ["mid", "none", "fast", "slow"])
    }

    func test_sortAlphabetical_byTitle() async {
        let sut = makeSUT(catalog: MockCatalogService.returning(catalog()))
        await sut.load()

        sut.sort = .alphabetical
        XCTAssertEqual(sut.tracks.map(\.title), ["A mid", "B slow", "C fast", "D none"])
    }

    func test_emptyCatalog_yieldsEmptyState() async {
        let sut = makeSUT(catalog: MockCatalogService.returning(.empty))
        await sut.load()
        XCTAssertEqual(sut.state, .empty)
    }

    func test_failure_yieldsRetryableError() async {
        let sut = makeSUT(catalog: MockCatalogService.failing(.offline))
        await sut.load()
        guard case let .failed(_, retryable) = sut.state else {
            return XCTFail("Expected failed state")
        }
        XCTAssertTrue(retryable)
    }

    func test_onAppear_tracksScreenView() async {
        let analytics = SpyAnalytics()
        let sut = TracksViewModel(
            catalog: MockCatalogService.returning(catalog()),
            favourites: FavouritesStore(service: InMemoryFavouritesService()),
            analytics: analytics
        )
        await sut.onAppear()
        XCTAssertTrue(analytics.events.contains(.screenView(.tracks)))
    }
}
