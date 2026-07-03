import Core
import Foundation
import Services
import XCTest
@testable import Features

@MainActor
final class SavedViewModelTests: XCTestCase {
    private func catalog() -> Catalog {
        Catalog(
            djs: [Dj(id: "showtek", name: "Showtek", country: "Netherlands")],
            events: [Event(id: "defqon-1", name: "Defqon.1", country: "Netherlands")],
            genres: [Genre(id: "early", name: "Early Hardstyle")],
            sets: [
                makeSet(id: "a", year: 2005),
                makeSet(id: "b", year: 2007),
                makeSet(id: "c", year: 2006)
            ]
        )
    }

    private func makeSet(id: String, year: Int) -> HardstyleSet {
        HardstyleSet(
            id: id,
            title: id.uppercased(),
            djID: "showtek",
            eventID: "defqon-1",
            year: year,
            durationSeconds: 3600,
            youtubeID: id,
            genreIDs: ["early"]
        )
    }

    private func makeSUT(
        catalog: CatalogService,
        favourites: FavouritesService
    ) -> SavedViewModel {
        SavedViewModel(catalog: catalog, favourites: favourites, analytics: SpyAnalytics())
    }

    func test_load_showsOnlyFavouritedSets() async {
        let favourites = InMemoryFavouritesService(seed: [
            Favourite(setID: "a", savedAt: Date(timeIntervalSince1970: 1)),
            Favourite(setID: "c", savedAt: Date(timeIntervalSince1970: 2))
        ])
        let sut = makeSUT(catalog: MockCatalogService.returning(catalog()), favourites: favourites)

        await sut.onAppear()

        XCTAssertEqual(sut.state, .loaded)
        XCTAssertEqual(Set(sut.sets.map(\.id)), ["a", "c"])
        XCTAssertTrue(sut.sets.allSatisfy(\.isSaved))
    }

    func test_load_orderedMostRecentlySavedFirst() async {
        let favourites = InMemoryFavouritesService(seed: [
            Favourite(setID: "a", savedAt: Date(timeIntervalSince1970: 10)),
            Favourite(setID: "b", savedAt: Date(timeIntervalSince1970: 30)),
            Favourite(setID: "c", savedAt: Date(timeIntervalSince1970: 20))
        ])
        let sut = makeSUT(catalog: MockCatalogService.returning(catalog()), favourites: favourites)

        await sut.onAppear()

        XCTAssertEqual(sut.sets.map(\.id), ["b", "c", "a"])
    }

    func test_noFavourites_yieldsEmptyState() async {
        let sut = makeSUT(catalog: MockCatalogService.returning(catalog()), favourites: InMemoryFavouritesService())

        await sut.onAppear()

        XCTAssertEqual(sut.state, .empty)
        XCTAssertTrue(sut.sets.isEmpty)
    }

    func test_toggleSave_removesUnsavedSet() async {
        let favourites = InMemoryFavouritesService(seed: [Favourite(setID: "b", savedAt: Date())])
        let sut = makeSUT(catalog: MockCatalogService.returning(catalog()), favourites: favourites)
        await sut.onAppear()
        XCTAssertEqual(sut.sets.map(\.id), ["b"])

        await sut.toggleSave("b")

        XCTAssertTrue(sut.sets.isEmpty)
        XCTAssertEqual(sut.state, .empty)
    }

    func test_catalogFailure_yieldsError() async {
        let sut = makeSUT(catalog: MockCatalogService.failing(.offline), favourites: InMemoryFavouritesService())

        await sut.onAppear()

        guard case let .failed(_, retryable) = sut.state else {
            return XCTFail("Expected failed state")
        }
        XCTAssertTrue(retryable)
    }

    func test_onAppear_tracksScreenView() async {
        let analytics = SpyAnalytics()
        let sut = SavedViewModel(
            catalog: MockCatalogService.returning(catalog()),
            favourites: InMemoryFavouritesService(),
            analytics: analytics
        )

        await sut.onAppear()

        XCTAssertTrue(analytics.events.contains(.screenView("Saved")))
    }
}
