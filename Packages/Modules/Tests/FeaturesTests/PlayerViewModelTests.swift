import Foundation
import XCTest
@testable import Features

@MainActor
final class PlayerViewModelTests: XCTestCase {
    private let nowPlaying = NowPlaying(
        setID: "set-1",
        title: "Technoboy",
        subtitle: "Sensation 2004",
        artworkURL: nil,
        youtubeID: "abc123"
    )

    private func makeSUT(
        player: MockYouTubePlayer,
        analytics: SpyAnalytics = SpyAnalytics()
    ) -> PlayerViewModel {
        PlayerViewModel(nowPlaying: nowPlaying, player: player, analytics: analytics)
    }

    func test_start_loadsVideoAndEntersLoadingAndTracks() {
        let player = MockYouTubePlayer()
        let analytics = SpyAnalytics()
        let sut = makeSUT(player: player, analytics: analytics)

        sut.start()

        XCTAssertEqual(sut.state, .loading)
        XCTAssertEqual(player.loadedVideoID, "abc123")
        XCTAssertTrue(analytics.events.contains(.screenView("Player")))
    }

    func test_ready_triggersAutoplay() {
        let player = MockYouTubePlayer()
        let sut = makeSUT(player: player)

        player.emit(.ready)

        XCTAssertEqual(player.playCount, 1)
        withExtendedLifetime(sut) {}
    }

    func test_stateEvents_mapToState() {
        let player = MockYouTubePlayer()
        let sut = makeSUT(player: player)

        player.emit(.buffering)
        XCTAssertEqual(sut.state, .buffering)
        XCTAssertTrue(sut.isBuffering)

        player.emit(.playing)
        XCTAssertEqual(sut.state, .playing)
        XCTAssertTrue(sut.isPlaying)

        player.emit(.paused)
        XCTAssertEqual(sut.state, .paused)

        player.emit(.ended)
        XCTAssertEqual(sut.state, .ended)
    }

    func test_failedEvent_yieldsFailedState() {
        let player = MockYouTubePlayer()
        let sut = makeSUT(player: player)

        player.emit(.failed("boom"))

        XCTAssertEqual(sut.state, .failed(message: "boom"))
    }

    func test_progress_updatesTimesAndFraction() {
        let player = MockYouTubePlayer()
        let sut = makeSUT(player: player)

        player.emit(.progress(time: 30, duration: 120))

        XCTAssertEqual(sut.duration, 120)
        XCTAssertEqual(sut.progress, 0.25, accuracy: 0.0001)
        XCTAssertTrue(sut.canScrub)
        XCTAssertEqual(sut.currentTimeText, "0:30")
        XCTAssertEqual(sut.durationText, "2:00")
    }

    func test_togglePlayPause_pausesWhenPlaying_playsOtherwise() {
        let player = MockYouTubePlayer()
        let sut = makeSUT(player: player)

        player.emit(.playing)
        sut.togglePlayPause()
        XCTAssertEqual(player.pauseCount, 1)

        player.emit(.paused)
        sut.togglePlayPause()
        XCTAssertEqual(player.playCount, 1)
    }

    func test_seek_clampsAndForwardsAndUpdatesTime() {
        let player = MockYouTubePlayer()
        let sut = makeSUT(player: player)
        player.emit(.progress(time: 0, duration: 100))

        sut.seek(toFraction: 1.5) // clamped to 1

        XCTAssertEqual(player.lastSeekFraction, 1)
        XCTAssertEqual(sut.currentTime, 100, accuracy: 0.0001)
    }

    func test_retry_reloads() {
        let player = MockYouTubePlayer()
        let sut = makeSUT(player: player)
        player.emit(.failed("x"))

        sut.retry()

        XCTAssertEqual(sut.state, .loading)
        XCTAssertEqual(player.loadedVideoID, "abc123")
    }

    func test_progress_withZeroDuration_isNotScrubbable() {
        let player = MockYouTubePlayer()
        let sut = makeSUT(player: player)

        XCTAssertFalse(sut.canScrub)
        XCTAssertEqual(sut.progress, 0)
    }
}
