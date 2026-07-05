import Core
import Foundation

/// Persistent favourites store backed by `UserDefaults` (a JSON-encoded list of
/// `Favourite`). Survives launches, stays behind the `FavouritesService`
/// protocol, and takes an injected `UserDefaults` suite + clock so tests are
/// deterministic and isolated.
///
/// Thread-safe via a lock (`UserDefaults` is itself thread-safe), so a single
/// instance can be shared across every screen's ViewModel.
public final class UserDefaultsFavouritesService: FavouritesService, @unchecked Sendable {
    /// Versioned storage key — bump on breaking format changes.
    public static let defaultKey = "favourites.v1"

    private let defaults: UserDefaults
    private let key: String
    private let now: @Sendable () -> Date
    private let lock = NSLock()
    private var storage: [HardstyleSet.ID: Date]

    public init(
        defaults: UserDefaults = .standard,
        key: String = UserDefaultsFavouritesService.defaultKey,
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.defaults = defaults
        self.key = key
        self.now = now
        storage = Self.decode(defaults.data(forKey: key))
    }

    public func all() async -> [Favourite] {
        lock.withLock {
            storage
                .map { Favourite(setID: $0.key, savedAt: $0.value) }
                .sorted { $0.savedAt > $1.savedAt }
        }
    }

    public func favouriteIDs() async -> Set<HardstyleSet.ID> {
        lock.withLock { Set(storage.keys) }
    }

    public func isFavourite(_ id: HardstyleSet.ID) async -> Bool {
        lock.withLock { storage[id] != nil }
    }

    @discardableResult
    public func toggle(_ id: HardstyleSet.ID) async -> Bool {
        lock.withLock {
            let nowSaved: Bool
            if storage[id] != nil {
                storage[id] = nil
                nowSaved = false
            } else {
                storage[id] = now()
                nowSaved = true
            }
            persistLocked()
            return nowSaved
        }
    }

    // MARK: - Persistence

    private func persistLocked() {
        let favourites = storage.map { Favourite(setID: $0.key, savedAt: $0.value) }
        let data = try? JSONEncoder().encode(favourites)
        defaults.set(data, forKey: key)
    }

    private static func decode(_ data: Data?) -> [HardstyleSet.ID: Date] {
        guard let data, let favourites = try? JSONDecoder().decode([Favourite].self, from: data) else {
            return [:]
        }
        return Dictionary(favourites.map { ($0.setID, $0.savedAt) }, uniquingKeysWith: { latest, _ in latest })
    }
}
