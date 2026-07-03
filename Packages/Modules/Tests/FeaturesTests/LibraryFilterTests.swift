import Core
import XCTest
@testable import Features

final class LibraryFilterTests: XCTestCase {
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
            genres: [
                Genre(id: "early", name: "Early Hardstyle"),
                Genre(id: "reverse", name: "Reverse Bass")
            ],
            sets: [
                makeSet(id: "a", djID: "showtek", eventID: "defqon-1", year: 2007, genres: ["early"]),
                makeSet(id: "b", djID: "technoboy", eventID: "qlimax", year: 2005, genres: ["reverse"]),
                makeSet(id: "c", djID: "showtek", eventID: "qlimax", year: 2007, genres: ["early", "reverse"])
            ]
        )
    }

    private func makeSet(id: String, djID: String, eventID: String, year: Int, genres: [String]) -> HardstyleSet {
        HardstyleSet(
            id: id,
            title: id.uppercased(),
            djID: djID,
            eventID: eventID,
            year: year,
            durationSeconds: 3600,
            youtubeID: id,
            genreIDs: genres
        )
    }

    private func matchingIDs(_ filter: LibraryFilter) -> Set<String> {
        filter.matchingIDs(in: catalog())
    }

    func test_emptyFilter_matchesEverything() {
        XCTAssertTrue(LibraryFilter().isEmpty)
        XCTAssertEqual(matchingIDs(LibraryFilter()), ["a", "b", "c"])
    }

    func test_filterByYear() {
        XCTAssertEqual(matchingIDs(LibraryFilter(years: [2007])), ["a", "c"])
    }

    func test_filterByEvent() {
        XCTAssertEqual(matchingIDs(LibraryFilter(eventIDs: ["qlimax"])), ["b", "c"])
    }

    func test_filterByGenre_isOrWithinFacet() {
        XCTAssertEqual(matchingIDs(LibraryFilter(genreIDs: ["reverse"])), ["b", "c"])
    }

    func test_filterByCountry() {
        XCTAssertEqual(matchingIDs(LibraryFilter(countries: ["Italy"])), ["b"])
    }

    func test_facets_areAndedTogether() {
        let filter = LibraryFilter(years: [2007], eventIDs: ["qlimax"])
        XCTAssertEqual(matchingIDs(filter), ["c"])
    }

    func test_activeCount_countsAllSelections() {
        let filter = LibraryFilter(years: [2005, 2007], eventIDs: ["qlimax"], countries: ["Italy"])
        XCTAssertEqual(filter.activeCount, 4)
    }

    func test_derive_optionsFromCatalogPresentAndSorted() {
        let options = FilterOptions.derive(from: catalog())
        XCTAssertEqual(options.years, [2007, 2005])
        XCTAssertEqual(options.events.map(\.name), ["Defqon.1", "Qlimax"])
        XCTAssertEqual(options.genres.map(\.name), ["Early Hardstyle", "Reverse Bass"])
        XCTAssertEqual(options.countries, ["Italy", "Netherlands"])
    }

    func test_derive_emptyCatalog_yieldsEmptyOptions() {
        XCTAssertTrue(FilterOptions.derive(from: .empty).isEmpty)
    }
}
