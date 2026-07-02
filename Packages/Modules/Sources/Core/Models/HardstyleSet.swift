import Foundation

/// A recorded DJ set — the central catalogue entity.
///
/// Named `HardstyleSet` rather than `Set` to avoid shadowing the standard
/// library. Relationships are expressed by stable identifiers (`djID`,
/// `eventID`, `genreIDs`) rather than nested objects, so the catalogue is a
/// normalised graph that is cheap to decode and to reshape in ViewModels.
public struct HardstyleSet: Identifiable, Hashable, Codable, Sendable {
    /// Stable slug identifier, e.g. `showtek-defqon1-2007`.
    public let id: String
    /// Set title as shown to the user.
    public let title: String
    /// Performing artist.
    public let djID: Dj.ID
    /// Event brand the set was played at.
    public let eventID: Event.ID
    /// Edition year (1999–2007 for the golden era).
    public let year: Int
    /// Runtime in whole seconds.
    public let durationSeconds: Int
    /// YouTube video identifier used by the official player and for artwork.
    public let youtubeID: String
    /// Genre tags applied to the set.
    public let genreIDs: [Genre.ID]

    public init(
        id: String,
        title: String,
        djID: Dj.ID,
        eventID: Event.ID,
        year: Int,
        durationSeconds: Int,
        youtubeID: String,
        genreIDs: [Genre.ID] = []
    ) {
        self.id = id
        self.title = title
        self.djID = djID
        self.eventID = eventID
        self.year = year
        self.durationSeconds = durationSeconds
        self.youtubeID = youtubeID
        self.genreIDs = genreIDs
    }

    /// Artwork URL derived from the YouTube video id — we never copy or
    /// self-host artwork, per project rules.
    public var thumbnailURL: URL? {
        URL(string: "https://i.ytimg.com/vi/\(youtubeID)/hqdefault.jpg")
    }

    /// Human-readable runtime, e.g. `1:08:45` or `58:20`.
    public var formattedDuration: String {
        Self.formatDuration(seconds: durationSeconds)
    }

    /// Formats a whole-second duration as `h:mm:ss` (dropping the hours segment
    /// when under an hour). Pure and testable.
    public static func formatDuration(seconds: Int) -> String {
        let clamped = max(0, seconds)
        let hours = clamped / 3600
        let minutes = (clamped % 3600) / 60
        let secs = clamped % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%d:%02d", minutes, secs)
    }
}
