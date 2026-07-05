import Core
import Foundation
import Services
import XCTest
@testable import Features

@MainActor
final class SearchViewModelTests: XCTestCase {
    private func catalog() -> Catalog {
        Catalog(
            djs: [
                Dj(id: "showtek", name: "Showtek", country: "Netherlands"),
                Dj(id: "technoboy", name: "Technoboy", country: "Italy")
            ],
            events: [
                Event(id: "defqon-1", name: "Defqon.1", country: "Netherlands"),
                Event(id: "qlimax", name: "Qlimax", country: "Netherlands")
            ],
            genres: [],
            sets: [
                HardstyleSet(
                    id: "rage",
                    title: "Technoboy — Rage",
                    djID: "technoboy",
                    eventID: "qlimax",
                    year: 2007,
                    durationSeconds: 3300,
                    youtubeID: "x"
                ),
                HardstyleSet(
                    id: "fts",
                    title: "Showtek — FTS",
                    djID: "showtek",
                    eventID: "defqon-1",
                    year: 2005,
                    durationSeconds: 3600,
                    youtubeID: "y"
                )
            ]
        )
    }

    private func makeSUT(recents: RecentSearchesStoring? = nil) -> SearchViewModel {
        SearchViewModel(
            catalog: MockCatalogService.returning(catalog()),
            favourites: FavouritesStore(service: InMemoryFavouritesService()),
            recents: recents ?? UserDefaultsRecentSearchesStore(key: "test.search.\(UUID().uuidString)"),
            analytics: SpyAnalytics()
        )
    }

    func test_query_groupsResultsAcrossSetsDJsAndEvents() async {
        let sut = makeSUT()
        await sut.onAppear()

        sut.query = "techno"
        let results = sut.results
        XCTAssertEqual(results.sets.map(\.id), ["rage"], "matches by DJ name reach the set group")
        XCTAssertEqual(results.djs.map(\.id), ["technoboy"])
        XCTAssertTrue(results.events.isEmpty)

        sut.query = "qlimax"
        XCTAssertEqual(sut.results.events.map(\.id), ["qlimax"])
        XCTAssertEqual(sut.results.sets.map(\.id), ["rage"], "matches by event name reach the set group")
    }

    func test_emptyQuery_yieldsNoResults() async {
        let sut = makeSUT()
        await sut.onAppear()
        XCTAssertTrue(sut.results.isEmpty)
    }

    func test_rememberQuery_persistsRecents() async {
        let recents = UserDefaultsRecentSearchesStore(key: "test.search.recents.\(UUID().uuidString)")
        let sut = makeSUT(recents: recents)
        await sut.onAppear()

        sut.query = "rage"
        sut.rememberQuery()

        XCTAssertEqual(sut.recentPhrases, ["rage"])
        XCTAssertEqual(recents.all(), ["rage"])
    }

    func test_eventSets_listsNewestFirst() async {
        let sut = makeSUT()
        await sut.onAppear()

        let event = Event(id: "qlimax", name: "Qlimax", country: "Netherlands")
        XCTAssertEqual(sut.sets(for: event).map(\.id), ["rage"])
    }
}
