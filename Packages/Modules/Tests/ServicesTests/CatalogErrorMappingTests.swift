import Foundation
import XCTest
@testable import Services

final class CatalogErrorMappingTests: XCTestCase {
    func test_passesThroughExistingCatalogError() {
        XCTAssertEqual(CatalogError.from(CatalogError.server(statusCode: 503)), .server(statusCode: 503))
    }

    func test_mapsOfflineURLErrors() {
        XCTAssertEqual(CatalogError.from(URLError(.notConnectedToInternet)), .offline)
        XCTAssertEqual(CatalogError.from(URLError(.networkConnectionLost)), .offline)
        XCTAssertEqual(CatalogError.from(URLError(.dataNotAllowed)), .offline)
    }

    func test_mapsTimeout() {
        XCTAssertEqual(CatalogError.from(URLError(.timedOut)), .timedOut)
    }

    func test_mapsOtherURLErrorToUnknown() {
        XCTAssertEqual(CatalogError.from(URLError(.badServerResponse)), .unknown)
    }

    func test_mapsDecodingErrorToDecodingFailed() {
        let decoding = DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "bad"))
        guard case .decodingFailed = CatalogError.from(decoding) else {
            return XCTFail("Expected decodingFailed")
        }
    }

    func test_mapsUnknownErrorToUnknown() {
        struct Weird: Error {}
        XCTAssertEqual(CatalogError.from(Weird()), .unknown)
    }
}
