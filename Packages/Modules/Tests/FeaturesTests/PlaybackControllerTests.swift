import Core
import Foundation
import Services
import XCTest
@testable import Features

@MainActor
final class PlaybackControllerTests: XCTestCase {
    /// Collects the mock engines created by the controller so tests can drive
    /// playback events on the current one. `@MainActor` so it is Sendable and
    /// can construct the (main-actor) mock engine.
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

    private func makeSUT() -> (PlaybackController, Engines) {
        let engines = Engines()
        let controller = PlaybackController(
            analytics: SpyAnalytics(),
            makeEngine: engines.make
        )
        return (controller, engines)
    }

    func test_play_startsQueueAtFirstAndExpands() {
        let (controller, engines) = makeSUT()

        controller.play([item("a"), item("b"), item("c")])

        XCTAssertEqual(controller.queue.map(\.id), ["a", "b", "c"])
        XCTAssertEqual(controller.nowPlaying?.setID, "a")
        XCTAssertTrue(controller.isExpanded)
        XCTAssertTrue(controller.hasCurrent)
        XCTAssertEqual(engines.list.last?.loadedVideoID, "yt-a")
    }

    func test_autoplay_advancesOnEnded() {
        let (controller, engines) = makeSUT()
        controller.play([item("a"), item("b")])

        engines.list.last?.emit(.ended) // end "a"

        XCTAssertEqual(controller.nowPlaying?.setID, "b")
        XCTAssertEqual(engines.list.last?.loadedVideoID, "yt-b")
    }

    func test_autoplayDisabled_staysOnEnded() {
        let (controller, engines) = makeSUT()
        controller.play([item("a"), item("b")])
        controller.autoplayNext = false

        engines.list.last?.emit(.ended)

        XCTAssertEqual(controller.nowPlaying?.setID, "a")
    }

    func test_advance_and_goPrevious_respectBounds() {
        let (controller, _) = makeSUT()
        controller.play([item("a"), item("b")])

        XCTAssertTrue(controller.canGoNext)
        XCTAssertFalse(controller.canGoPrevious)

        controller.advance()
        XCTAssertEqual(controller.nowPlaying?.setID, "b")
        XCTAssertFalse(controller.canGoNext)
        XCTAssertTrue(controller.canGoPrevious)

        controller.advance() // no-op at end
        XCTAssertEqual(controller.nowPlaying?.setID, "b")

        controller.goPrevious()
        XCTAssertEqual(controller.nowPlaying?.setID, "a")
    }

    func test_playAt_jumpsToTrack() {
        let (controller, _) = makeSUT()
        controller.play([item("a"), item("b"), item("c")])

        controller.play(at: 2)
        XCTAssertEqual(controller.nowPlaying?.setID, "c")
    }

    func test_enqueue_and_playNext() {
        let (controller, _) = makeSUT()
        controller.play([item("a"), item("b")])

        controller.enqueue(item("z"))
        XCTAssertEqual(controller.queue.map(\.id), ["a", "b", "z"])

        controller.playNext(item("m"))
        XCTAssertEqual(controller.queue.map(\.id), ["a", "m", "b", "z"])
    }

    func test_removeCurrent_advancesToNext() {
        let (controller, _) = makeSUT()
        controller.play([item("a"), item("b")])

        controller.remove(controller.queue[0]) // remove current "a"

        XCTAssertEqual(controller.queue.map(\.id), ["b"])
        XCTAssertEqual(controller.nowPlaying?.setID, "b")
    }

    func test_removeEarlier_keepsCurrentTrack() {
        let (controller, _) = makeSUT()
        controller.play([item("a"), item("b"), item("c")])
        controller.advance() // now on "b" (index 1)

        controller.remove(controller.queue[0]) // remove "a"

        XCTAssertEqual(controller.queue.map(\.id), ["b", "c"])
        XCTAssertEqual(controller.nowPlaying?.setID, "b")
    }

    func test_move_keepsCurrentTrack() {
        let (controller, _) = makeSUT()
        controller.play([item("a"), item("b"), item("c")])
        controller.advance() // current "b"

        controller.move(fromOffsets: IndexSet(integer: 0), toOffset: 3) // move "a" to end

        XCTAssertEqual(controller.queue.map(\.id), ["b", "c", "a"])
        XCTAssertEqual(controller.nowPlaying?.setID, "b")
    }

    /// Regression for the track-switching bug: creating an engine per track left
    /// the new engine's web view outside the view hierarchy, so the on-screen
    /// player kept showing the old video. The controller must reuse ONE engine
    /// and load every track into it.
    func test_trackChanges_reuseTheSameEngine() {
        let (controller, engines) = makeSUT()

        controller.play([item("a"), item("b"), item("c")])
        XCTAssertEqual(engines.current?.loadedVideoID, "yt-a")

        controller.advance()
        XCTAssertEqual(engines.list.count, 1, "advancing must reuse the on-screen engine")
        XCTAssertEqual(engines.current?.loadedVideoID, "yt-b")

        controller.play(at: 2)
        XCTAssertEqual(engines.list.count, 1, "queue jumps must reuse the on-screen engine")
        XCTAssertEqual(engines.current?.loadedVideoID, "yt-c")
    }

    func test_collapse_keepsCurrentPlaying() {
        let (controller, _) = makeSUT()
        controller.play([item("a")])
        XCTAssertTrue(controller.isExpanded)

        controller.collapse()

        XCTAssertFalse(controller.isExpanded)
        XCTAssertTrue(controller.hasCurrent, "collapsing must not stop playback")
    }

    func test_backgroundRoundTrip_resumesPlaybackOnReturn() {
        let (controller, engines) = makeSUT()
        controller.play([item("a")])
        engines.current?.emit(.playing)
        let playsBefore = engines.current?.playCount ?? 0

        controller.appDidEnterBackground()
        engines.current?.emit(.paused) // the system suspends the web player
        controller.appDidBecomeActive()

        XCTAssertEqual(engines.current?.playCount, playsBefore + 1, "returning must resume playback")
    }

    func test_backgroundRoundTrip_staysPausedWhenUserHadPaused() {
        let (controller, engines) = makeSUT()
        controller.play([item("a")])
        engines.current?.emit(.paused) // user paused before backgrounding
        let playsBefore = engines.current?.playCount ?? 0

        controller.appDidEnterBackground()
        controller.appDidBecomeActive()

        XCTAssertEqual(engines.current?.playCount, playsBefore, "a user pause must survive the round trip")
    }

    func test_emptyQueue_hasNoCurrent() {
        let (controller, _) = makeSUT()
        controller.play([])
        XCTAssertFalse(controller.hasCurrent)
    }
}
