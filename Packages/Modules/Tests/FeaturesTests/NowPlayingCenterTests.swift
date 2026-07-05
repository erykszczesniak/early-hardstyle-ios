import MediaPlayer
import XCTest
@testable import Features

@MainActor
final class NowPlayingCenterTests: XCTestCase {
    override func tearDown() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        super.tearDown()
    }

    func test_playbackPublishesNowPlayingMetadata() {
        let engines = EnginesBox()
        let controller = PlaybackController(
            analytics: SpyAnalytics(),
            progress: SpyProgressStore(),
            makeEngine: engines.make
        )

        controller.play([NowPlaying(
            setID: "a",
            title: "Technoboy — Rage",
            subtitle: "Qlimax 2007",
            artworkURL: nil,
            source: .youtube(id: "x")
        )])
        engines.last?.emit(.progress(time: 42, duration: 3300))

        let info = MPNowPlayingInfoCenter.default().nowPlayingInfo
        XCTAssertEqual(info?[MPMediaItemPropertyTitle] as? String, "Technoboy — Rage")
        XCTAssertEqual(info?[MPMediaItemPropertyArtist] as? String, "Qlimax 2007")
        XCTAssertEqual(info?[MPNowPlayingInfoPropertyElapsedPlaybackTime] as? Double, 42)
        XCTAssertEqual(info?[MPMediaItemPropertyPlaybackDuration] as? Double, 3300)
    }
}

/// Minimal engine factory box for this test file.
@MainActor
private final class EnginesBox {
    private(set) var list: [MockPlaybackEngine] = []

    var last: MockPlaybackEngine? {
        list.last
    }

    func make(_: PlaybackSource) -> PlaybackEngine {
        let engine = MockPlaybackEngine()
        list.append(engine)
        return engine
    }
}
