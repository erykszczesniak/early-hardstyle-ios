import Foundation

/// One entry of a set's tracklist: its position, the "Artist - Title" line and
/// (when the source tracklist carries timestamps) the offset into the set.
public struct SetTrack: Identifiable, Hashable, Codable, Sendable {
    /// 1-based position within the set.
    public let number: Int
    /// Full display line, e.g. "Zany - Pillz".
    public let title: String
    /// Offset from the start of the set in whole seconds. Nil when the source
    /// tracklist lists titles without timestamps.
    public let startSeconds: Int?

    /// Tracks are unique by position within their set.
    public var id: Int {
        number
    }

    public init(number: Int, title: String, startSeconds: Int? = nil) {
        self.number = number
        self.title = title
        self.startSeconds = startSeconds
    }

    /// Human-readable start offset, e.g. `3:50` — nil when unknown.
    public var formattedStart: String? {
        startSeconds.map { HardstyleSet.formatDuration(seconds: $0) }
    }
}
