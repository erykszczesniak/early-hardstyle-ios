import Foundation

/// Persists the user's recent search phrases (most recent first, deduplicated,
/// capped). Synchronous by design, like the other lightweight stores.
public protocol RecentSearchesStoring: Sendable {
    func all() -> [String]
    func add(_ phrase: String)
    func clear()
}

public final class UserDefaultsRecentSearchesStore: RecentSearchesStoring, @unchecked Sendable {
    /// Versioned storage key — bump on breaking format changes.
    public static let defaultKey = "recent-searches.v1"

    private let defaults: UserDefaults
    private let key: String
    private let limit: Int
    private let lock = NSLock()
    private var phrases: [String]

    public init(
        defaults: UserDefaults = .standard,
        key: String = UserDefaultsRecentSearchesStore.defaultKey,
        limit: Int = 8
    ) {
        self.defaults = defaults
        self.key = key
        self.limit = limit
        phrases = defaults.stringArray(forKey: key) ?? []
    }

    public func all() -> [String] {
        lock.withLock { phrases }
    }

    public func add(_ phrase: String) {
        let trimmed = phrase.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        lock.withLock {
            phrases.removeAll { $0.caseInsensitiveCompare(trimmed) == .orderedSame }
            phrases.insert(trimmed, at: 0)
            phrases = Array(phrases.prefix(limit))
            defaults.set(phrases, forKey: key)
        }
    }

    public func clear() {
        lock.withLock {
            phrases = []
            defaults.set(phrases, forKey: key)
        }
    }
}
