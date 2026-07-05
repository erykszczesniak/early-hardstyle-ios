import Core
import Foundation
import XCTest

final class DeepLinkTests: XCTestCase {
    func test_parsesPlaySet() throws {
        let url = try XCTUnwrap(URL(string: "earlyhs://play/tb-rage"))
        XCTAssertEqual(DeepLink.parse(url), .play(setID: "tb-rage"))
    }

    func test_parsesPlayLatest() throws {
        let url = try XCTUnwrap(URL(string: "earlyhs://play/latest"))
        XCTAssertEqual(DeepLink.parse(url), .playLatest)
    }

    func test_rejectsForeignAndMalformedURLs() throws {
        for bad in ["https://play/x", "earlyhs://open/x", "earlyhs://play", "earlyhs://play/"] {
            let url = try XCTUnwrap(URL(string: bad))
            XCTAssertNil(DeepLink.parse(url), bad)
        }
    }

    func test_roundTripsThroughURL() throws {
        let link = DeepLink.play(setID: "hh-destiny")
        let url = try XCTUnwrap(link.url)
        XCTAssertEqual(DeepLink.parse(url), link)
    }
}
