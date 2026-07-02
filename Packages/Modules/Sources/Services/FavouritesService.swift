import Core
import Foundation

/// Stores the user's saved sets. Features depend on this protocol; the live
/// implementation (persistent, feature #8) and the in-memory mock below are
/// both interchangeable at the composition root.
public protocol FavouritesService: Sendable {
    /// All favourites, most-recently-saved first.
    func all() async -> [Favourite]
    /// The set of currently-favourited set ids, for fast membership checks.
    func favouriteIDs() async -> Set<HardstyleSet.ID>
    /// Whether a given set is currently saved.
    func isFavourite(_ id: HardstyleSet.ID) async -> Bool
    /// Toggles a set's saved state and returns the new state (`true` == saved).
    @discardableResult
    func toggle(_ id: HardstyleSet.ID) async -> Bool
}

/// In-memory favourites store backing tests, previews and the app until the
/// persistent store lands. An `actor` so concurrent toggles are data-race free.
///
/// `now` is injected so `savedAt` ordering is deterministic in tests.
public actor InMemoryFavouritesService: FavouritesService {
    private var storage: [HardstyleSet.ID: Date]
    private let now: @Sendable () -> Date

    public init(seed: [Favourite] = [], now: @escaping @Sendable () -> Date = Date.init) {
        storage = Dictionary(seed.map { ($0.setID, $0.savedAt) }, uniquingKeysWith: { latest, _ in latest })
        self.now = now
    }

    public func all() -> [Favourite] {
        storage
            .map { Favourite(setID: $0.key, savedAt: $0.value) }
            .sorted { $0.savedAt > $1.savedAt }
    }

    public func favouriteIDs() -> Set<HardstyleSet.ID> {
        Set(storage.keys)
    }

    public func isFavourite(_ id: HardstyleSet.ID) -> Bool {
        storage[id] != nil
    }

    @discardableResult
    public func toggle(_ id: HardstyleSet.ID) -> Bool {
        if storage[id] != nil {
            storage[id] = nil
            return false
        }
        storage[id] = now()
        return true
    }
}
