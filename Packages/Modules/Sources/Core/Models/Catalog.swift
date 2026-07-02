import Foundation

/// The full decoded catalogue: a normalised graph of DJs, events, genres and
/// sets. Services return a `Catalog`; ViewModels reshape it for their screens.
public struct Catalog: Codable, Equatable, Sendable {
    public let djs: [Dj]
    public let events: [Event]
    public let genres: [Genre]
    public let sets: [HardstyleSet]

    public init(djs: [Dj], events: [Event], genres: [Genre], sets: [HardstyleSet]) {
        self.djs = djs
        self.events = events
        self.genres = genres
        self.sets = sets
    }

    /// An empty catalogue — the natural "loaded but nothing to show" value.
    public static let empty = Catalog(djs: [], events: [], genres: [], sets: [])

    // MARK: - Lookups (O(1))

    private var djsByID: [Dj.ID: Dj] {
        Dictionary(djs.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    }

    private var eventsByID: [Event.ID: Event] {
        Dictionary(events.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    }

    private var genresByID: [Genre.ID: Genre] {
        Dictionary(genres.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    }

    /// The performing DJ for a set, if present in the catalogue.
    public func dj(for set: HardstyleSet) -> Dj? {
        djsByID[set.djID]
    }

    /// The event brand for a set, if present in the catalogue.
    public func event(for set: HardstyleSet) -> Event? {
        eventsByID[set.eventID]
    }

    /// The genres attached to a set, resolved in declared order (unknown ids
    /// are skipped).
    public func genres(for set: HardstyleSet) -> [Genre] {
        let lookup = genresByID
        return set.genreIDs.compactMap { lookup[$0] }
    }

    /// All sets by a given DJ, newest edition first.
    public func sets(byDJ djID: Dj.ID) -> [HardstyleSet] {
        sets.filter { $0.djID == djID }.sorted { $0.year > $1.year }
    }
}
