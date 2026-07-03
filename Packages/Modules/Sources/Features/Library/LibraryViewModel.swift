import Core
import DesignSystem
import Foundation
import Services

/// Explicit lifecycle state for the Library screen — never nil-inferred.
public enum LibraryState: Equatable {
    case loading
    case loaded
    case empty
    case failed(message: String, retryable: Bool)
}

/// Drives the Library screen: loads the catalogue, maps it to card models,
/// reconciles favourites, and exposes search — all as explicit state.
@MainActor
@Observable
public final class LibraryViewModel {
    private let catalog: CatalogService
    private let favourites: FavouritesService
    private let analytics: any Analytics

    public private(set) var state: LibraryState = .loading
    public var searchQuery: String = ""

    private var catalogData: Catalog = .empty
    private var favouriteIDs: Set<HardstyleSet.ID> = []
    private var allSets: [SetCardModel] = []

    public init(catalog: CatalogService, favourites: FavouritesService, analytics: any Analytics) {
        self.catalog = catalog
        self.favourites = favourites
        self.analytics = analytics
    }

    /// Sets matching the current search query (case-insensitive over title and
    /// event). Returns everything when the query is blank.
    public var visibleSets: [SetCardModel] {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return allSets }
        return allSets.filter {
            $0.title.lowercased().contains(query) || $0.eventName.lowercased().contains(query)
        }
    }

    /// True when a non-empty search yields no matches on an otherwise-loaded
    /// catalogue.
    public var hasNoSearchResults: Bool {
        state == .loaded && !allSets.isEmpty && visibleSets.isEmpty
    }

    /// The newest set, surfaced by the hero's "Play latest" action.
    public var latestSet: SetCardModel? {
        allSets.first
    }

    public func onAppear() async {
        analytics.trackScreenView("Library")
        if state == .loading { await load() }
    }

    public func load() async {
        state = .loading
        await fetch()
    }

    public func retry() async {
        await load()
    }

    public func refresh() async {
        await fetch()
    }

    public func toggleSave(_ id: HardstyleSet.ID) async {
        let nowSaved = await favourites.toggle(id)
        if nowSaved {
            favouriteIDs.insert(id)
        } else {
            favouriteIDs.remove(id)
        }
        allSets = Self.map(catalogData, favourites: favouriteIDs)
    }

    private func fetch() async {
        do {
            let loaded = try await catalog.loadCatalog()
            catalogData = loaded
            favouriteIDs = await favourites.favouriteIDs()
            allSets = Self.map(loaded, favourites: favouriteIDs)
            state = allSets.isEmpty ? .empty : .loaded
        } catch {
            let catalogError = (error as? CatalogError) ?? .unknown
            state = .failed(
                message: catalogError.errorDescription ?? "Something went wrong.",
                retryable: catalogError.isRetryable
            )
        }
    }

    /// Maps a catalogue into card models, newest first. Pure and testable.
    static func map(_ catalog: Catalog, favourites: Set<HardstyleSet.ID>) -> [SetCardModel] {
        catalog.sets
            .sorted { $0.year > $1.year }
            .map { set in
                SetCardModel(
                    id: set.id,
                    title: set.title,
                    eventName: catalog.event(for: set)?.name ?? "Unknown event",
                    year: set.year,
                    durationSeconds: set.durationSeconds,
                    genres: catalog.genres(for: set).map(\.name),
                    thumbnailURL: set.thumbnailURL,
                    isSaved: favourites.contains(set.id)
                )
            }
    }
}
