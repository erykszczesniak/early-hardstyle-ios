import Core
import Foundation
import Services
import XCTest
@testable import Features

@MainActor
final class DJDetailViewModelTests: XCTestCase {
    private let showtek = Dj(id: "showtek", name: "Showtek", country: "Netherlands")

    private func catalog() -> Catalog {
        Catalog(
            djs: [showtek, Dj(id: "technoboy", name: "Technoboy", country: "Italy")],
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

    private func makeSUT(favourites: FavouritesService = InMemoryFavouritesService()) -> DJDetailViewModel {
        DJDetailViewModel(dj: showtek, catalog: catalog(), favourites: favourites, analytics: SpyAnalytics())
    }

    func test_onAppear_showsOnlyThisDJsSetsNewestFirst() async {
        let sut = makeSUT()

        await sut.onAppear()

        XCTAssertEqual(sut.sets.map(\.id), ["s2", "s1"])
        XCTAssertEqual(sut.setCount, 2)
        XCTAssertEqual(sut.subtitle, "Netherlands · 2 sets")
    }

    func test_onAppear_reflectsFavourites() async {
        let favourites = InMemoryFavouritesService(seed: [Favourite(setID: "s1", savedAt: Date())])
        let sut = makeSUT(favourites: favourites)

        await sut.onAppear()

        XCTAssertEqual(sut.sets.first { $0.id == "s1" }?.isSaved, true)
        XCTAssertEqual(sut.sets.first { $0.id == "s2" }?.isSaved, false)
    }

    func test_toggleSave_updatesAndPersists() async {
        let favourites = InMemoryFavouritesService()
        let sut = makeSUT(favourites: favourites)
        await sut.onAppear()

        await sut.toggleSave("s2")

        XCTAssertEqual(sut.sets.first { $0.id == "s2" }?.isSaved, true)
        let stored = await favourites.isFavourite("s2")
        XCTAssertTrue(stored)
    }

    func test_onAppear_tracksScreenView() async {
        let analytics = SpyAnalytics()
        let sut = DJDetailViewModel(
            dj: showtek,
            catalog: catalog(),
            favourites: InMemoryFavouritesService(),
            analytics: analytics
        )

        await sut.onAppear()

        XCTAssertTrue(analytics.events.contains(.screenView("DJ Detail")))
    }
}
