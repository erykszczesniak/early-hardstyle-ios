import Foundation

/// A saved (favourited) set in the user's personal library.
///
/// Stored as a small value keyed by the set id plus the moment it was saved, so
/// the Saved screen can present favourites most-recent-first.
public struct Favourite: Identifiable, Hashable, Codable, Sendable {
    /// The favourited set's id — also the identity of the favourite itself
    /// (a set can be saved at most once).
    public let setID: HardstyleSet.ID
    /// When the set was saved.
    public let savedAt: Date

    public var id: HardstyleSet.ID {
        setID
    }

    public init(setID: HardstyleSet.ID, savedAt: Date) {
        self.setID = setID
        self.savedAt = savedAt
    }
}
