import Foundation
import SwiftUI

/// Engine abstraction over a playback backend (the official YouTube embed, a
/// licensed AVPlayer audio source, …). The Player ViewModel depends on this
/// protocol, never on a concrete backend, so playback logic is unit-testable
/// with a mock and engines are swappable per source kind.
///
/// Deliberately **UI-free**: engines that render video additionally conform to
/// ``VideoSurfaceProviding``; the mock doesn't have to fake a view (the Liskov
/// smell flagged in the architecture audit).
@MainActor
public protocol PlaybackEngine: AnyObject {
    /// Callback the engine invokes as playback state/progress changes.
    var onEvent: ((PlaybackEvent) -> Void)? { get set }

    /// Loads (and prepares) the given source, optionally starting mid-way (the
    /// resume point for long sets).
    func load(_ source: PlaybackSource, startAt seconds: Int?)
    func play()
    func pause()
    /// Seeks to a `0...1` fraction of the video's duration.
    func seek(toFraction fraction: Double)
}

/// Conformed to by engines that render video. The **view layer** (not the
/// ViewModel) asks for the surface, keeping UI out of the engine contract.
@MainActor
public protocol VideoSurfaceProviding: AnyObject {
    /// The SwiftUI surface that renders the video (the embedded player).
    var surface: AnyView { get }
}

/// A test double that records commands and lets tests drive playback events.
@MainActor
public final class MockPlaybackEngine: PlaybackEngine {
    public var onEvent: ((PlaybackEvent) -> Void)?

    public private(set) var loadedSource: PlaybackSource?
    public private(set) var loadedStartAt: Int?
    public private(set) var playCount = 0
    public private(set) var pauseCount = 0
    public private(set) var lastSeekFraction: Double?

    public init() {}

    public func load(_ source: PlaybackSource, startAt seconds: Int?) {
        loadedSource = source
        loadedStartAt = seconds
    }

    /// Convenience for assertions on YouTube sources.
    public var loadedVideoID: String? {
        if case let .youtube(id) = loadedSource { id } else { nil }
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
