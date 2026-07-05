import Core
import Foundation

/// A remembered playback position for one set.
public struct PlaybackPosition: Codable, Equatable, Sendable {
    public let seconds: Int
    public let duration: Int
    public let updatedAt: Date

    public init(seconds: Int, duration: Int, updatedAt: Date) {
        self.seconds = seconds
        self.duration = duration
        self.updatedAt = updatedAt
    }

    /// Progress in `0...1` (0 when the duration is unknown).
    public var fraction: Double {
        guard duration > 0 else { return 0 }
        return min(max(Double(seconds) / Double(duration), 0), 1)
    }
}

/// Persists per-set playback positions so hour-long sets resume where the
/// listener left off. Synchronous by design (backed by thread-safe storage) so
/// the playback controller can read a resume point without hopping actors.
public protocol PlaybackProgressStoring: Sendable {
    func position(for id: HardstyleSet.ID) -> PlaybackPosition?
    /// Records a position, applying resume semantics (see the implementation).
    func save(seconds: Int, duration: Int, for id: HardstyleSet.ID)
    func clear(for id: HardstyleSet.ID)
    /// Most-recently-updated first.
    func recent(limit: Int) -> [(id: HardstyleSet.ID, position: PlaybackPosition)]
}

/// `UserDefaults`-backed store with classic resume semantics:
/// - positions in the first `minimumSeconds` are not worth remembering,
/// - passing `completionFraction` of the set counts as finished and clears the
///   entry (so a finished set restarts from the top).
public final class UserDefaultsPlaybackProgressStore: PlaybackProgressStoring, @unchecked Sendable {
    /// Versioned storage key — bump on breaking format changes.
    public static let defaultKey = "playback-progress.v1"

    private let defaults: UserDefaults
    private let key: String
    private let now: @Sendable () -> Date
    private let minimumSeconds: Int
    private let completionFraction: Double
    private let lock = NSLock()
    private var storage: [HardstyleSet.ID: PlaybackPosition]

    public init(
        defaults: UserDefaults = .standard,
        key: String = UserDefaultsPlaybackProgressStore.defaultKey,
        minimumSeconds: Int = 30,
        completionFraction: Double = 0.95,
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.defaults = defaults
        self.key = key
        self.minimumSeconds = minimumSeconds
        self.completionFraction = completionFraction
        self.now = now
        storage = Self.decode(defaults.data(forKey: key))
    }

    public func position(for id: HardstyleSet.ID) -> PlaybackPosition? {
        lock.withLock { storage[id] }
    }

    public func save(seconds: Int, duration: Int, for id: HardstyleSet.ID) {
        lock.withLock {
            guard seconds >= minimumSeconds else { return }
            if duration > 0, Double(seconds) / Double(duration) >= completionFraction {
                storage[id] = nil
            } else {
                storage[id] = PlaybackPosition(seconds: seconds, duration: duration, updatedAt: now())
            }
            persistLocked()
        }
    }

    public func clear(for id: HardstyleSet.ID) {
        lock.withLock {
            storage[id] = nil
            persistLocked()
        }
    }

    public func recent(limit: Int) -> [(id: HardstyleSet.ID, position: PlaybackPosition)] {
        lock.withLock {
            storage
                .sorted { $0.value.updatedAt > $1.value.updatedAt }
                .prefix(limit)
                .map { (id: $0.key, position: $0.value) }
        }
    }

    // MARK: - Persistence

    private func persistLocked() {
        let data = try? JSONEncoder().encode(storage)
        defaults.set(data, forKey: key)
    }

    private static func decode(_ data: Data?) -> [HardstyleSet.ID: PlaybackPosition] {
        guard let data,
              let stored = try? JSONDecoder().decode([HardstyleSet.ID: PlaybackPosition].self, from: data)
        else { return [:] }
        return stored
    }
}
