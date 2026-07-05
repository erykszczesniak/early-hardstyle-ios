import AVFoundation
import XCTest
@testable import Features

@MainActor
final class AVPlayerAudioEngineTests: XCTestCase {
    /// Writes a short silent audio file the real AVPlayer can play end-to-end.
    private func makeAudioFile(seconds: Double = 0.4) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("engine-test-\(UUID().uuidString).caf")
        let format = try XCTUnwrap(AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1))
        let file = try AVAudioFile(forWriting: url, settings: format.settings)
        let frames = AVAudioFrameCount(44100 * seconds)
        let buffer = try XCTUnwrap(AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames))
        buffer.frameLength = frames
        try file.write(from: buffer)
        return url
    }

    func test_playsALocalFileThroughTheFullLifecycle() async throws {
        let url = try makeAudioFile()
        let engine = AVPlayerAudioEngine()
        var events: [PlaybackEvent] = []
        let ready = expectation(description: "ready")
        let ended = expectation(description: "ended")

        engine.onEvent = { event in
            events.append(event)
            if case .ready = event {
                ready.fulfill()
                engine.play()
            }
            if case .ended = event {
                ended.fulfill()
            }
        }

        engine.load(.audio(url: url), startAt: nil)
        await fulfillment(of: [ready, ended], timeout: 10)

        XCTAssertTrue(events.contains(.playing), "the engine must report real playback")
        let progressed = events.contains { if case .progress = $0 { true } else { false } }
        XCTAssertTrue(progressed, "progress ticks must flow")
    }

    func test_unplayableURL_reportsFailure() async {
        let engine = AVPlayerAudioEngine()
        let failed = expectation(description: "failed")
        engine.onEvent = { event in
            if case .failed = event {
                failed.fulfill()
            }
        }

        let missing = FileManager.default.temporaryDirectory.appendingPathComponent("missing.caf")
        engine.load(.audio(url: missing), startAt: nil)
        await fulfillment(of: [failed], timeout: 10)
    }

    func test_youtubeSource_isRejectedWithDesignedFailure() {
        let engine = AVPlayerAudioEngine()
        var failed = false
        engine.onEvent = { if case .failed = $0 { failed = true } }

        engine.load(.youtube(id: "abc"), startAt: nil)

        XCTAssertTrue(failed, "the audio engine cannot play YouTube sources")
    }
}
