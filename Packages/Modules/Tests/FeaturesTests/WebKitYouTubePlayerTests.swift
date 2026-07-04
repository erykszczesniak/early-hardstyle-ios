import XCTest
@testable import Features

@MainActor
final class WebKitYouTubePlayerTests: XCTestCase {
    /// Regression test for the JS-bridge retain cycle: registering the engine
    /// directly as the `WKScriptMessageHandler` made a `WKUserContentController`
    /// retain it strongly, so it never deallocated. With the weak proxy in
    /// place, dropping the last strong reference must deallocate the engine.
    func test_engineDeallocates_noRetainCycleViaScriptMessageHandler() {
        weak var weakEngine: WebKitYouTubePlayer?

        autoreleasepool {
            let engine = WebKitYouTubePlayer()
            weakEngine = engine
            XCTAssertNotNil(weakEngine)
        }

        XCTAssertNil(weakEngine, "the engine must deallocate — the script message handler must not retain it")
    }
}
