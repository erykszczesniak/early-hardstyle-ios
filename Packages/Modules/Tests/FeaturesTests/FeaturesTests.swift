import XCTest
@testable import Features

final class FeaturesTests: XCTestCase {
    func test_moduleName_isFeatures() {
        XCTAssertEqual(Features.moduleName, "Features")
    }
}
