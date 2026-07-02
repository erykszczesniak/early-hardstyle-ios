import XCTest
@testable import Services

final class ServicesTests: XCTestCase {
    func test_moduleName_isServices() {
        XCTAssertEqual(Services.moduleName, "Services")
    }

    func test_servicesBuildOnCore() {
        XCTAssertEqual(Services.coreModuleName, "Core")
    }
}
