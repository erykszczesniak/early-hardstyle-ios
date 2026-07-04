import Core
import Foundation
import Services
import XCTest
@testable import Features

/// Characterization tests: they pin the *current* observable behaviour of the
/// player + queue seams so the upcoming engine/state refactors can be proven
/// behaviour-preserving. If a refactor changes any of these, it's a regression
/// (or a deliberate, separately-reviewed behaviour change).
@MainActor
final class PlaybackCharacterizationTests: XCTestCase {
    /// Collects the mock engines the controller creates, so a test can drive
    /// events on the current one. `@MainActor` so it is Sendable and can build
    /// the main-actor mock.
    @MainActor
    private final class Engines {
        var list: [MockYouTubePlayer] = []
        func make() -> YouTubePlayer {
            let engine = MockYouTubePlayer()
            list.append(engine)
            return engine
        }

        var current: MockYouTubePlayer? {
            list.last
        }
    }

    private func item(_ id: String) -> NowPlaying {
        NowPlaying(setID: id, title: id.uppercased(), subtitle: "sub", artworkURL: nil, youtubeID: "yt-\(id)")
    }

    // MARK: Player lifecycle

    func test_characterize_playerLifecycle_readyAutoplaysThenTracksToEnded() {
        let player = MockYouTubePlayer()
        var endedCalls = 0
        let sut = PlayerViewModel(
            nowPlaying: item("a"),
            player: player,
            analytics: SpyAnalytics()
        )
        sut.onPlaybackEnded = { endedCalls += 1 }

        sut.start()
        XCTAssertEqual(sut.state, .loading)
        XCTAssertEqual(player.loadedVideoID, "yt-a")

        player.emit(.ready)
        XCTAssertEqual(player.playCount, 1, "ready autoplays")

        player.emit(.buffering)
        XCTAssertEqual(sut.state, .buffering)

        player.emit(.playing)
        XCTAssertEqual(sut.state, .playing)

        player.emit(.progress(time: 30, duration: 120))
        XCTAssertEqual(sut.progress, 0.25, accuracy: 0.0001)

        player.emit(.ended)
        XCTAssertEqual(sut.state, .ended)
        XCTAssertEqual(endedCalls, 1, "ended notifies the queue exactly once")
    }

    func test_characterize_playerFailure_isRetryable() {
        let player = MockYouTubePlayer()
        let sut = PlayerViewModel(nowPlaying: item("a"), player: player, analytics: SpyAnalytics())

        player.emit(.failed("boom"))
        XCTAssertEqual(sut.state, .failed(message: "boom"))

        sut.retry()
        XCTAssertEqual(sut.state, .loading)
        XCTAssertEqual(player.loadedVideoID, "yt-a")
    }

    // MARK: Queue autoplay chain

    func test_characterize_autoplayChain_advancesThroughQueueThenStops() {
        let engines = Engines()
        let controller = PlaybackController(
            analytics: SpyAnalytics(),
            makeEngine: engines.make
        )

        controller.play([item("a"), item("b"), item("c")])
        XCTAssertEqual(controller.nowPlaying?.setID, "a")

        engines.current?.emit(.ended)
        XCTAssertEqual(controller.nowPlaying?.setID, "b", "autoplay advances a → b")

        engines.current?.emit(.ended)
        XCTAssertEqual(controller.nowPlaying?.setID, "c", "autoplay advances b → c")

        engines.current?.emit(.ended)
        XCTAssertEqual(controller.nowPlaying?.setID, "c", "no next track → stays on c")
    }

    func test_characterize_autoplayOff_holdsOnCurrent() {
        let engines = Engines()
        let controller = PlaybackController(
            analytics: SpyAnalytics(),
            makeEngine: engines.make
        )
        controller.play([item("a"), item("b")])
        controller.autoplayNext = false

        engines.current?.emit(.ended)
        XCTAssertEqual(controller.nowPlaying?.setID, "a", "autoplay off holds on the current track")
    }
}
