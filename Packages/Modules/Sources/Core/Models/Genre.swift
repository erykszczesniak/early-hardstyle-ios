import Foundation

/// A hardstyle sub-genre / tag (e.g. "Early Hardstyle", "Reverse Bass",
/// "Nu-style"). Modelled as data rather than a fixed enum so the catalogue can
/// evolve without code changes.
public struct Genre: Identifiable, Hashable, Codable, Sendable {
    /// Stable slug identifier, e.g. `early-hardstyle`.
    public let id: String
    /// Display name, e.g. "Early Hardstyle".
    public let name: String

    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}
