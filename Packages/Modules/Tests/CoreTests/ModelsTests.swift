import Foundation
import XCTest
@testable import Core

final class ModelsTests: XCTestCase {
    /// A representative slice of the catalogue as it will arrive on the wire.
    private let catalogJSON = """
    {
      "djs": [
        { "id": "showtek", "name": "Showtek", "country": "Netherlands",
          "imageURL": "https://example.com/showtek.jpg", "bio": "Duo from Eindhoven." },
        { "id": "technoboy", "name": "Technoboy", "country": "Italy" }
      ],
      "events": [
        { "id": "defqon-1", "name": "Defqon.1", "country": "Netherlands" }
      ],
      "genres": [
        { "id": "early-hardstyle", "name": "Early Hardstyle" },
        { "id": "reverse-bass", "name": "Reverse Bass" }
      ],
      "sets": [
        {
          "id": "showtek-defqon1-2007",
          "title": "Showtek at Defqon.1 2007",
          "djID": "showtek",
          "eventID": "defqon-1",
          "year": 2007,
          "durationSeconds": 4125,
          "youtubeID": "dQw4w9WgXcQ",
          "genreIDs": ["early-hardstyle", "reverse-bass"]
        }
      ]
    }
    """

    private func decodeCatalog() throws -> Catalog {
        try JSONDecoder().decode(Catalog.self, from: Data(catalogJSON.utf8))
    }

    private func makeSet(id: String, djID: Dj.ID, year: Int) -> HardstyleSet {
        HardstyleSet(
            id: id,
            title: id.uppercased(),
            djID: djID,
            eventID: "defqon-1",
            year: year,
            durationSeconds: 60,
            youtubeID: id
        )
    }

    func test_catalog_decodesAllEntities() throws {
        let catalog = try decodeCatalog()

        XCTAssertEqual(catalog.djs.count, 2)
        XCTAssertEqual(catalog.events.count, 1)
        XCTAssertEqual(catalog.genres.count, 2)
        XCTAssertEqual(catalog.sets.count, 1)
    }

    func test_dj_decodesOptionalFields() throws {
        let catalog = try decodeCatalog()

        let showtek = try XCTUnwrap(catalog.djs.first { $0.id == "showtek" })
        XCTAssertEqual(showtek.name, "Showtek")
        XCTAssertEqual(showtek.imageURL, URL(string: "https://example.com/showtek.jpg"))
        XCTAssertEqual(showtek.bio, "Duo from Eindhoven.")

        let technoboy = try XCTUnwrap(catalog.djs.first { $0.id == "technoboy" })
        XCTAssertNil(technoboy.imageURL)
        XCTAssertNil(technoboy.bio)
    }

    func test_set_thumbnailURL_derivesFromYouTubeID() throws {
        let set = try XCTUnwrap(decodeCatalog().sets.first)
        XCTAssertEqual(
            set.thumbnailURL,
            URL(string: "https://i.ytimg.com/vi/dQw4w9WgXcQ/hqdefault.jpg")
        )
    }

    func test_catalog_resolvesRelationships() throws {
        let catalog = try decodeCatalog()
        let set = try XCTUnwrap(catalog.sets.first)

        XCTAssertEqual(catalog.dj(for: set)?.name, "Showtek")
        XCTAssertEqual(catalog.event(for: set)?.name, "Defqon.1")
        XCTAssertEqual(catalog.genres(for: set).map(\.name), ["Early Hardstyle", "Reverse Bass"])
    }

    func test_catalog_setsByDJ_sortedNewestFirst() {
        let older = makeSet(id: "a", djID: "showtek", year: 2005)
        let newer = makeSet(id: "b", djID: "showtek", year: 2007)
        let other = makeSet(id: "c", djID: "technoboy", year: 2006)
        let catalog = Catalog(djs: [], events: [], genres: [], sets: [older, newer, other])

        XCTAssertEqual(catalog.sets(byDJ: "showtek").map(\.id), ["b", "a"])
    }

    func test_youtubeThumbnail_buildsBothQualities() {
        XCTAssertEqual(
            YouTubeThumbnail.url(videoID: "abc123XYZ_-"),
            URL(string: "https://i.ytimg.com/vi/abc123XYZ_-/hqdefault.jpg")
        )
        XCTAssertEqual(
            YouTubeThumbnail.url(videoID: "abc123XYZ_-", quality: .medium),
            URL(string: "https://i.ytimg.com/vi/abc123XYZ_-/mqdefault.jpg")
        )
    }

    func test_formatDuration() {
        XCTAssertEqual(HardstyleSet.formatDuration(seconds: 4125), "1:08:45")
        XCTAssertEqual(HardstyleSet.formatDuration(seconds: 3500), "58:20")
        XCTAssertEqual(HardstyleSet.formatDuration(seconds: 5), "0:05")
        XCTAssertEqual(HardstyleSet.formatDuration(seconds: 0), "0:00")
        XCTAssertEqual(HardstyleSet.formatDuration(seconds: -10), "0:00")
        XCTAssertEqual(HardstyleSet.formatDuration(seconds: 3600), "1:00:00")
    }

    func test_catalog_roundTripsThroughCodable() throws {
        let original = try decodeCatalog()
        let data = try JSONEncoder().encode(original)
        let restored = try JSONDecoder().decode(Catalog.self, from: data)
        XCTAssertEqual(original, restored)
    }

    func test_malformedJSON_throws() {
        let bad = Data(#"{ "djs": "not-an-array" }"#.utf8)
        XCTAssertThrowsError(try JSONDecoder().decode(Catalog.self, from: bad))
    }
}
