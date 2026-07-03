import Core
import Foundation

/// A multi-facet filter over the catalogue: year, event brand, genre and DJ
/// country. Empty facets match everything. Pure and testable — no UI.
public struct LibraryFilter: Equatable, Sendable {
    public var years: Set<Int>
    public var eventIDs: Set<Event.ID>
    public var genreIDs: Set<Genre.ID>
    public var countries: Set<String>

    public init(
        years: Set<Int> = [],
        eventIDs: Set<Event.ID> = [],
        genreIDs: Set<Genre.ID> = [],
        countries: Set<String> = []
    ) {
        self.years = years
        self.eventIDs = eventIDs
        self.genreIDs = genreIDs
        self.countries = countries
    }

    /// No facet is constrained.
    public var isEmpty: Bool {
        years.isEmpty && eventIDs.isEmpty && genreIDs.isEmpty && countries.isEmpty
    }

    /// Total number of selected values across all facets (for the badge).
    public var activeCount: Int {
        years.count + eventIDs.count + genreIDs.count + countries.count
    }

    /// Whether a set satisfies every constrained facet (AND across facets,
    /// OR within a facet).
    public func matches(_ set: HardstyleSet, in catalog: Catalog) -> Bool {
        if !years.isEmpty, !years.contains(set.year) { return false }
        if !eventIDs.isEmpty, !eventIDs.contains(set.eventID) { return false }
        if !genreIDs.isEmpty, genreIDs.isDisjoint(with: set.genreIDs) { return false }
        if !countries.isEmpty {
            guard let country = catalog.dj(for: set)?.country, countries.contains(country) else { return false }
        }
        return true
    }

    /// The ids of sets in the catalogue that pass the filter.
    public func matchingIDs(in catalog: Catalog) -> Set<HardstyleSet.ID> {
        Set(catalog.sets.filter { matches($0, in: catalog) }.map(\.id))
    }
}

/// The selectable filter values actually present in a catalogue, so the UI only
/// offers facets that can match something. Derived once per load.
public struct FilterOptions: Equatable, Sendable {
    public let years: [Int]
    public let events: [Event]
    public let genres: [Genre]
    public let countries: [String]

    public init(years: [Int], events: [Event], genres: [Genre], countries: [String]) {
        self.years = years
        self.events = events
        self.genres = genres
        self.countries = countries
    }

    public static let empty = FilterOptions(years: [], events: [], genres: [], countries: [])

    public var isEmpty: Bool {
        years.isEmpty && events.isEmpty && genres.isEmpty && countries.isEmpty
    }

    /// Derives the available options from the sets present in the catalogue.
    public static func derive(from catalog: Catalog) -> FilterOptions {
        let years = Set(catalog.sets.map(\.year)).sorted(by: >)

        let presentEventIDs = Set(catalog.sets.map(\.eventID))
        let events = catalog.events
            .filter { presentEventIDs.contains($0.id) }
            .sorted { $0.name < $1.name }

        let presentGenreIDs = Set(catalog.sets.flatMap(\.genreIDs))
        let genres = catalog.genres
            .filter { presentGenreIDs.contains($0.id) }
            .sorted { $0.name < $1.name }

        let countries = Set(catalog.sets.compactMap { catalog.dj(for: $0)?.country }).sorted()

        return FilterOptions(years: years, events: events, genres: genres, countries: countries)
    }
}
