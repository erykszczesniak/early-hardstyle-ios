import XCTest
import YouTubeiOSPlayerHelper
@testable import Features

@MainActor
final class OfficialYouTubePlayerTests: XCTestCase {
    /// The audit retain-cycle lesson, kept as a regression test
    /// on the new engine: dropping the last strong reference must deallocate it
    /// (YTPlayerView holds its delegate weakly).
    func test_engineDeallocates() {
        weak var weakEngine: OfficialYouTubePlayer?

        autoreleasepool {
            let engine = OfficialYouTubePlayer()
            weakEngine = engine
            XCTAssertNotNil(weakEngine)
        }

        XCTAssertNil(weakEngine, "the engine must deallocate when released")
    }

    func test_errorMessages_areUserFacing() {
        XCTAssertTrue(
            OfficialYouTubePlayer.message(for: .notEmbeddable).contains("owner"),
            "embed-blocked videos should explain the restriction"
        )
        XCTAssertEqual(OfficialYouTubePlayer.message(for: .videoNotFound), "This video is unavailable.")
        XCTAssertEqual(OfficialYouTubePlayer.message(for: .invalidParam), "This video is unavailable.")
        XCTAssertFalse(OfficialYouTubePlayer.message(for: .unknown).isEmpty)
    }
}
