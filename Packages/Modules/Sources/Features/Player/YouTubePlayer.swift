import Foundation
import SwiftUI

/// Engine abstraction over the official YouTube iframe player. The Player
/// ViewModel depends on this protocol, never on WebKit, so playback logic is
/// unit-testable with a mock and the real engine is swappable.
@MainActor
public protocol YouTubePlayer: AnyObject {
    /// Callback the engine invokes as playback state/progress changes.
    var onEvent: ((PlaybackEvent) -> Void)? { get set }

    /// The SwiftUI surface that renders the video (the embedded player).
    var surface: AnyView { get }

    /// Loads (and prepares) the given video.
    func load(videoID: String)
    func play()
    func pause()
    /// Seeks to a `0...1` fraction of the video's duration.
    func seek(toFraction fraction: Double)
}

public extension YouTubePlayer {
    /// Default surface for engines without a visible view (e.g. the test mock).
    var surface: AnyView {
        AnyView(Color.black)
    }
}

/// A test double that records commands and lets tests drive playback events.
@MainActor
public final class MockYouTubePlayer: YouTubePlayer {
    public var onEvent: ((PlaybackEvent) -> Void)?

    public private(set) var loadedVideoID: String?
    public private(set) var playCount = 0
    public private(set) var pauseCount = 0
    public private(set) var lastSeekFraction: Double?

    public init() {}

    public func load(videoID: String) {
        loadedVideoID = videoID
    }

    public func play() {
        playCount += 1
    }

    public func pause() {
        pauseCount += 1
    }

    public func seek(toFraction fraction: Double) {
        lastSeekFraction = fraction
    }

    /// Simulates an engine event reaching the ViewModel.
    public func emit(_ event: PlaybackEvent) {
        onEvent?(event)
    }
}
