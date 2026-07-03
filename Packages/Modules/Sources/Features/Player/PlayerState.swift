import Foundation

/// Explicit player lifecycle state, surfaced to the UI as first-class states.
public enum PlayerState: Equatable, Sendable {
    case idle
    case loading
    case buffering
    case playing
    case paused
    case ended
    case failed(message: String)
}

/// Events emitted by a `YouTubePlayer` engine, mapped from the YouTube iframe
/// player's own state/progress callbacks. The single vocabulary the ViewModel
/// reacts to — engine-agnostic so a mock can drive it in tests.
public enum PlaybackEvent: Equatable, Sendable {
    case ready
    case buffering
    case playing
    case paused
    case ended
    case failed(String)
    case progress(time: Double, duration: Double)
}

/// The immutable "now playing" descriptor handed to the player.
public struct NowPlaying: Equatable, Sendable, Identifiable {
    /// The catalogue set id — used to reconcile favourites.
    public let setID: String
    public let title: String
    public let subtitle: String
    public let artworkURL: URL?
    public let youtubeID: String

    public var id: String {
        setID
    }

    public init(setID: String, title: String, subtitle: String, artworkURL: URL?, youtubeID: String) {
        self.setID = setID
        self.title = title
        self.subtitle = subtitle
        self.artworkURL = artworkURL
        self.youtubeID = youtubeID
    }
}
