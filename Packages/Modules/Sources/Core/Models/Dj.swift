import Foundation

/// A hardstyle artist / DJ.
public struct Dj: Identifiable, Hashable, Codable, Sendable {
    /// Stable slug identifier, e.g. `showtek`.
    public let id: String
    /// Display name, e.g. "Showtek".
    public let name: String
    /// ISO-ish country label, e.g. "Netherlands".
    public let country: String
    /// Optional avatar image URL. Absent for artists without artwork.
    public let imageURL: URL?
    /// Optional short biography.
    public let bio: String?

    public init(
        id: String,
        name: String,
        country: String,
        imageURL: URL? = nil,
        bio: String? = nil
    ) {
        self.id = id
        self.name = name
        self.country = country
        self.imageURL = imageURL
        self.bio = bio
    }
}
