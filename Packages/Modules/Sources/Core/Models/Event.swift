import Foundation

/// An event brand under which sets were performed (e.g. Defqon.1, Qlimax,
/// Sensation). A specific edition is expressed by pairing an event with a year
/// on ``HardstyleSet``.
public struct Event: Identifiable, Hashable, Codable, Sendable {
    /// Stable slug identifier, e.g. `defqon-1`.
    public let id: String
    /// Display name / brand, e.g. "Defqon.1".
    public let name: String
    /// Country the brand is associated with, e.g. "Netherlands".
    public let country: String

    public init(id: String, name: String, country: String) {
        self.id = id
        self.name = name
        self.country = country
    }
}
