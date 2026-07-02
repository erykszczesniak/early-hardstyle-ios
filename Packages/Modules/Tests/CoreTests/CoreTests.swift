import XCTest
@testable import Core

final class CoreTests: XCTestCase {
    func test_moduleName_isCore() {
        XCTAssertEqual(Core.moduleName, "Core")
    }
}
