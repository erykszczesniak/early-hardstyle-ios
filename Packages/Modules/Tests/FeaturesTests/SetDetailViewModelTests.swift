import Core
import Foundation
import Services
import XCTest
@testable import Features

@MainActor
final class SetDetailViewModelTests: XCTestCase {
    private let primary = HardstyleSet(
        id: "p",
        title: "Showtek at Defqon.1 2007",
        djID: "showtek",
        eventID: "defqon-1",
        year: 2007,
        durationSeconds: 4125,
        youtubeID: "yt-p",
        genreIDs: ["early"]
    )

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
            genres: [Genre(id: "early", name: "Early Hardstyle")],
            sets: [
                primary,
                makeSet(id: "sameEvent", djID: "technoboy", eventID: "defqon-1", year: 2006),
                makeSet(id: "sameDJ", djID: "showtek", eventID: "qlimax", year: 2005),
                makeSet(id: "unrelated", djID: "technoboy", eventID: "qlimax", year: 2004)
            ]
        )
    }

    private func makeSet(id: String, djID: String, eventID: String, year: Int) -> HardstyleSet {
        HardstyleSet(
            id: id,
            title: id,
            djID: djID,
            eventID: eventID,
            year: year,
            durationSeconds: 3600,
            youtubeID: id,
            genreIDs: ["early"]
        )
    }

    private func makeSUT(favourites: FavouritesService = InMemoryFavouritesService()) -> SetDetailViewModel {
        SetDetailViewModel(set: primary, catalog: catalog(), favourites: favourites, analytics: SpyAnalytics())
    }

    func test_related_sameEventOrDJ_excludingSelf_newestFirst() {
        let related = SetDetailViewModel.related(to: primary, in: catalog())
        XCTAssertEqual(related.map(\.id), ["sameEvent", "sameDJ"])
    }

    func test_header_fields() {
        let sut = makeSUT()
        XCTAssertEqual(sut.title, "Showtek at Defqon.1 2007")
        XCTAssertEqual(sut.djName, "Showtek")
        XCTAssertEqual(sut.metaLine, "Defqon.1 2007 · 1:08:45")
        XCTAssertEqual(sut.genres, ["Early Hardstyle"])
        XCTAssertEqual(sut.youtubeID, "yt-p")
    }

    func test_onAppear_buildsCardAndRelatedAndTracks() async {
        let analytics = SpyAnalytics()
        let sut = SetDetailViewModel(
            set: primary,
            catalog: catalog(),
            favourites: InMemoryFavouritesService(),
            analytics: analytics
        )

        await sut.onAppear()

        XCTAssertEqual(sut.card.id, "p")
        XCTAssertEqual(sut.related.map(\.id), ["sameEvent", "sameDJ"])
        XCTAssertTrue(analytics.events.contains(.screenView("Set Detail")))
    }

    func test_toggleSavePrimary_updatesAndPersists() async {
        let favourites = InMemoryFavouritesService()
        let sut = makeSUT(favourites: favourites)
        await sut.onAppear()
        XCTAssertFalse(sut.isSaved)

        await sut.toggleSavePrimary()

        XCTAssertTrue(sut.isSaved)
        let stored = await favourites.isFavourite("p")
        XCTAssertTrue(stored)
    }

    func test_toggleRelated_updatesThatCard() async {
        let sut = makeSUT()
        await sut.onAppear()

        await sut.toggleSave("sameEvent")

        XCTAssertEqual(sut.related.first { $0.id == "sameEvent" }?.isSaved, true)
        XCTAssertEqual(sut.related.first { $0.id == "sameDJ" }?.isSaved, false)
    }

    func test_detailViewModel_forRelated_buildsForThatSet() async throws {
        let sut = makeSUT()
        await sut.onAppear()

        let relatedCard = try? XCTUnwrap(sut.related.first)
        let nested = try sut.detailViewModel(for: XCTUnwrap(relatedCard))
        XCTAssertEqual(nested?.card.id, "sameEvent")
    }
}
