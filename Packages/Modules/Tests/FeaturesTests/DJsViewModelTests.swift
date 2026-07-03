import Core
import DesignSystem
import Foundation
import Services
import XCTest
@testable import Features

@MainActor
final class DJsViewModelTests: XCTestCase {
    private func catalog() -> Catalog {
        Catalog(
            djs: [
                Dj(id: "showtek", name: "Showtek", country: "Netherlands"),
                Dj(id: "technoboy", name: "Technoboy", country: "Italy"),
                Dj(id: "alusion", name: "A-lusion", country: "Netherlands")
            ],
            events: [Event(id: "defqon-1", name: "Defqon.1", country: "Netherlands")],
            genres: [Genre(id: "early", name: "Early Hardstyle")],
            sets: [
                makeSet(id: "s1", djID: "showtek", year: 2005),
                makeSet(id: "s2", djID: "showtek", year: 2007),
                makeSet(id: "s3", djID: "technoboy", year: 2006)
            ]
        )
    }

    private func makeSet(id: String, djID: String, year: Int) -> HardstyleSet {
        HardstyleSet(
            id: id,
            title: id.uppercased(),
            djID: djID,
            eventID: "defqon-1",
            year: year,
            durationSeconds: 3600,
            youtubeID: id,
            genreIDs: ["early"]
        )
    }

    private func makeSUT(
        catalog: CatalogService,
        favourites: FavouritesService = InMemoryFavouritesService(),
        analytics: SpyAnalytics = SpyAnalytics()
    ) -> DJsViewModel {
        DJsViewModel(catalog: catalog, favourites: favourites, analytics: analytics)
    }

    func test_load_success_buildsCardsAlphabeticallyWithCounts() async {
        let sut = makeSUT(catalog: MockCatalogService.returning(catalog()))

        await sut.load()

        XCTAssertEqual(sut.state, .loaded)
        XCTAssertEqual(sut.visibleDJs.map(\.name), ["A-lusion", "Showtek", "Technoboy"])
        XCTAssertEqual(sut.visibleDJs.first { $0.id == "showtek" }?.setCount, 2)
        XCTAssertEqual(sut.visibleDJs.first { $0.id == "alusion" }?.setCount, 0)
    }

    func test_load_emptyCatalog_yieldsEmptyState() async {
        let sut = makeSUT(catalog: MockCatalogService.returning(.empty))
        await sut.load()
        XCTAssertEqual(sut.state, .empty)
    }

    func test_load_failure_yieldsRetryableError() async {
        let sut = makeSUT(catalog: MockCatalogService.failing(.timedOut))
        await sut.load()
        guard case let .failed(_, retryable) = sut.state else {
            return XCTFail("Expected failed state")
        }
        XCTAssertTrue(retryable)
    }

    func test_search_filtersByNameAndCountry() async {
        let sut = makeSUT(catalog: MockCatalogService.returning(catalog()))
        await sut.load()

        sut.searchQuery = "italy"
        XCTAssertEqual(sut.visibleDJs.map(\.id), ["technoboy"])

        sut.searchQuery = "show"
        XCTAssertEqual(sut.visibleDJs.map(\.id), ["showtek"])
    }

    func test_detailViewModel_forKnownDJ_hasThatDJsSets() async throws {
        let sut = makeSUT(catalog: MockCatalogService.returning(catalog()))
        await sut.load()

        let card = try? XCTUnwrap(sut.visibleDJs.first { $0.id == "showtek" })
        let detail = try sut.detailViewModel(for: XCTUnwrap(card))
        XCTAssertEqual(detail?.dj.id, "showtek")
        XCTAssertEqual(detail?.setCount, 2)
    }

    func test_detailViewModel_forUnknownDJ_isNil() async {
        let sut = makeSUT(catalog: MockCatalogService.returning(catalog()))
        await sut.load()

        let ghost = DJCardModel(id: "ghost", name: "Ghost", country: "Nowhere", setCount: 0, imageURL: nil)
        XCTAssertNil(sut.detailViewModel(for: ghost))
    }

    func test_onAppear_tracksScreenView() async {
        let analytics = SpyAnalytics()
        let sut = makeSUT(catalog: MockCatalogService.returning(catalog()), analytics: analytics)
        await sut.onAppear()
        XCTAssertTrue(analytics.events.contains(.screenView("DJs")))
    }
}
