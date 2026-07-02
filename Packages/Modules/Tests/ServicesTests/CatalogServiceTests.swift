import Core
import XCTest
@testable import Services

final class CatalogServiceTests: XCTestCase {
    private var sampleCatalog: Catalog {
        Catalog(
            djs: [Dj(id: "showtek", name: "Showtek", country: "Netherlands")],
            events: [Event(id: "defqon-1", name: "Defqon.1", country: "Netherlands")],
            genres: [Genre(id: "early-hardstyle", name: "Early Hardstyle")],
            sets: [HardstyleSet(
                id: "s1",
                title: "Set",
                djID: "showtek",
                eventID: "defqon-1",
                year: 2007,
                durationSeconds: 60,
                youtubeID: "abc"
            )]
        )
    }

    func test_mock_returning_deliversCatalog() async throws {
        let service = MockCatalogService.returning(sampleCatalog)
        let catalog = try await service.loadCatalog()
        XCTAssertEqual(catalog, sampleCatalog)
    }

    func test_mock_failing_throwsTypedError() async {
        let service = MockCatalogService.failing(.offline)
        do {
            _ = try await service.loadCatalog()
            XCTFail("Expected loadCatalog to throw")
        } catch let error as CatalogError {
            XCTAssertEqual(error, .offline)
        } catch {
            XCTFail("Expected CatalogError, got \(error)")
        }
    }

    func test_mock_withDelay_stillDelivers() async throws {
        let service = MockCatalogService.returning(sampleCatalog, delay: .milliseconds(10))
        let catalog = try await service.loadCatalog()
        XCTAssertEqual(catalog.sets.count, 1)
    }

    func test_catalogError_isRetryable() {
        XCTAssertTrue(CatalogError.offline.isRetryable)
        XCTAssertTrue(CatalogError.timedOut.isRetryable)
        XCTAssertTrue(CatalogError.server(statusCode: 500).isRetryable)
        XCTAssertTrue(CatalogError.unknown.isRetryable)
        XCTAssertFalse(CatalogError.decodingFailed("bad key").isRetryable)
    }

    func test_catalogError_hasUserFacingDescription() {
        let cases: [CatalogError] = [
            .offline, .timedOut, .decodingFailed("x"), .server(statusCode: 503), .unknown
        ]
        for error in cases {
            XCTAssertFalse((error.errorDescription ?? "").isEmpty, "missing message for \(error)")
        }
    }
}
