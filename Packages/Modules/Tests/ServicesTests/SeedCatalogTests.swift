import Core
import XCTest
@testable import Services

final class SeedCatalogTests: XCTestCase {
    private let catalog = SeedCatalog.catalog

    func test_catalog_isPopulated() {
        XCTAssertFalse(catalog.djs.isEmpty)
        XCTAssertFalse(catalog.events.isEmpty)
        XCTAssertFalse(catalog.genres.isEmpty)
        XCTAssertGreaterThanOrEqual(catalog.sets.count, 10)
    }

    func test_setIDs_areUnique() {
        let ids = catalog.sets.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count)
    }

    func test_youtubeIDs_areUniqueAndWellFormed() {
        let ids = catalog.sets.map(\.youtubeID)
        XCTAssertEqual(ids.count, Set(ids).count, "duplicate YouTube ids")
        for id in ids {
            XCTAssertEqual(id.count, 11, "YouTube id \(id) is not 11 characters")
        }
    }

    func test_everySet_referencesExistingEntities() {
        let djIDs = Set(catalog.djs.map(\.id))
        let eventIDs = Set(catalog.events.map(\.id))
        let genreIDs = Set(catalog.genres.map(\.id))

        for set in catalog.sets {
            XCTAssertTrue(djIDs.contains(set.djID), "unknown DJ \(set.djID) in \(set.id)")
            XCTAssertTrue(eventIDs.contains(set.eventID), "unknown event \(set.eventID) in \(set.id)")
            for genre in set.genreIDs {
                XCTAssertTrue(genreIDs.contains(genre), "unknown genre \(genre) in \(set.id)")
            }
        }
    }

    func test_everySet_hasArtworkAndPlausibleYearAndDuration() {
        for set in catalog.sets {
            XCTAssertNotNil(set.thumbnailURL, "no artwork for \(set.id)")
            // Event sets are golden-era; classics mixes carry their upload year.
            XCTAssertTrue((1999 ... 2026).contains(set.year), "implausible year for \(set.id)")
            XCTAssertGreaterThan(set.durationSeconds, 0)
        }
    }

    func test_tracklists_areWellFormed() {
        for set in catalog.sets {
            let numbers = set.tracks.map(\.number)
            XCTAssertEqual(
                numbers,
                (0 ..< set.tracks.count).map { $0 + 1 },
                "tracklist numbering for \(set.id) is not 1…n"
            )
            for track in set.tracks {
                XCTAssertFalse(track.title.isEmpty, "empty track title in \(set.id)")
            }
            let starts = set.tracks.compactMap(\.startSeconds)
            XCTAssertEqual(starts, starts.sorted(), "timestamps out of order in \(set.id)")
            if let last = starts.last {
                XCTAssertLessThan(last, set.durationSeconds, "timestamp past the end of \(set.id)")
            }
        }
    }

    func test_onlineMixes_areSeededWithTracklists() {
        let mixIDs = ["hoc-energy-mix", "hoc-oldschool-resurrection", "ljq-oldschool-revolution"]
        for id in mixIDs {
            let set = catalog.sets.first { $0.id == id }
            XCTAssertNotNil(set, "missing seeded mix \(id)")
            XCTAssertFalse(set?.tracks.isEmpty ?? true, "mix \(id) has no tracklist")
        }
        XCTAssertEqual(catalog.sets.first { $0.id == "hoc-energy-mix" }?.tracks.count, 16)
        XCTAssertEqual(catalog.sets.first { $0.id == "hoc-oldschool-resurrection" }?.tracks.count, 21)
        XCTAssertEqual(catalog.sets.first { $0.id == "ljq-oldschool-revolution" }?.tracks.count, 30)
    }

    func test_everySet_hasAnEraPlausibleBPM() {
        for set in catalog.sets {
            let bpm = try? XCTUnwrap(set.bpm, "set \(set.id) has no BPM")
            XCTAssertTrue((135 ... 155).contains(bpm ?? 0), "implausible BPM for \(set.id)")
        }
    }

    func test_everyDJ_hasAnOfficialThumbnailAvatar() {
        for dj in catalog.djs {
            let url = try? XCTUnwrap(dj.imageURL, "DJ \(dj.id) has no avatar")
            XCTAssertEqual(url?.host, "i.ytimg.com", "avatars must be official YouTube thumbnails")
        }
    }

    func test_everyDJ_hasAtLeastOneSet() {
        for dj in catalog.djs {
            XCTAssertFalse(catalog.sets(byDJ: dj.id).isEmpty, "DJ \(dj.id) has no sets")
        }
    }

    func test_bundledService_returnsSeed() async throws {
        let loaded = try await BundledCatalogService().loadCatalog()
        XCTAssertEqual(loaded, catalog)
    }
}
