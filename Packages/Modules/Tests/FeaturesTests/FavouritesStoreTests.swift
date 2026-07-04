import Core
import Foundation
import Services
import XCTest
@testable import Features

@MainActor
final class FavouritesStoreTests: XCTestCase {
    func test_load_syncsIDsFromService() async {
        let service = InMemoryFavouritesService(seed: [Favourite(setID: "a", savedAt: Date())])
        let store = FavouritesStore(service: service)

        await store.load()

        XCTAssertEqual(store.ids, ["a"])
        XCTAssertTrue(store.isFavourite("a"))
        XCTAssertFalse(store.isFavourite("b"))
    }

    func test_toggle_updatesIDsAndPersists() async {
        let service = InMemoryFavouritesService()
        let store = FavouritesStore(service: service)

        let saved = await store.toggle("a")
        XCTAssertTrue(saved)
        XCTAssertTrue(store.isFavourite("a"))

        let removed = await store.toggle("a")
        XCTAssertFalse(removed)
        XCTAssertFalse(store.isFavourite("a"))

        let persisted = await service.isFavourite("a")
        XCTAssertFalse(persisted)
    }

    func test_orderedFavourites_passesThroughServiceOrdering() async {
        let service = InMemoryFavouritesService(seed: [
            Favourite(setID: "old", savedAt: Date(timeIntervalSince1970: 1)),
            Favourite(setID: "new", savedAt: Date(timeIntervalSince1970: 2))
        ])
        let store = FavouritesStore(service: service)

        let ordered = await store.orderedFavourites()
        XCTAssertEqual(ordered.map(\.setID), ["new", "old"])
    }

    /// The single-source-of-truth property this refactor exists for: a toggle
    /// through one screen's ViewModel is immediately visible on another screen
    /// sharing the store — no onAppear reconciliation needed.
    func test_toggleOnOneScreen_isLiveOnAnother() async {
        let service = InMemoryFavouritesService()
        let store = FavouritesStore(service: service)
        let catalog = Catalog(
            djs: [Dj(id: "showtek", name: "Showtek", country: "Netherlands")],
            events: [Event(id: "defqon-1", name: "Defqon.1", country: "Netherlands")],
            genres: [],
            sets: [HardstyleSet(
                id: "s1",
                title: "Set",
                djID: "showtek",
                eventID: "defqon-1",
                year: 2007,
                durationSeconds: 60,
                youtubeID: "x"
            )]
        )

        let library = LibraryViewModel(
            catalog: MockCatalogService.returning(catalog),
            favourites: store,
            analytics: SpyAnalytics()
        )
        let djDetail = DJDetailViewModel(
            dj: Dj(id: "showtek", name: "Showtek", country: "Netherlands"),
            catalog: catalog,
            favourites: store,
            analytics: SpyAnalytics()
        )
        await library.load()

        // Toggle on the DJ detail screen…
        await djDetail.toggleSave("s1")

        // …and the Library card is saved immediately, without reloading.
        XCTAssertEqual(library.visibleSets.first?.isSaved, true)
        XCTAssertEqual(djDetail.sets.first?.isSaved, true)
    }
}
