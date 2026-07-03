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
    public var filter = LibraryFilter()
    public private(set) var filterOptions: FilterOptions = .empty

    private var catalogData: Catalog = .empty
    private var favouriteIDs: Set<HardstyleSet.ID> = []
    private var allSets: [SetCardModel] = []

    public init(catalog: CatalogService, favourites: FavouritesService, analytics: any Analytics) {
        self.catalog = catalog
        self.favourites = favourites
        self.analytics = analytics
    }

    /// Sets matching the active filter and search query. The filter runs at the
    /// domain level (year/event/genre/country); search is a case-insensitive
    /// match over title and event.
    public var visibleSets: [SetCardModel] {
        var result = allSets
        if !filter.isEmpty {
            let allowed = filter.matchingIDs(in: catalogData)
            result = result.filter { allowed.contains($0.id) }
        }
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !query.isEmpty {
            result = result.filter {
                $0.title.lowercased().contains(query) || $0.eventName.lowercased().contains(query)
            }
        }
        return result
    }

    /// True when the catalogue has sets but the active filter/search hide them all.
    public var hasNoResults: Bool {
        state == .loaded && !allSets.isEmpty && visibleSets.isEmpty
    }

    /// Number of selected filter values, for the toolbar badge.
    public var activeFilterCount: Int {
        filter.activeCount
    }

    /// Whether any refining (filter or search) is currently applied.
    public var isRefining: Bool {
        !filter.isEmpty || !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    public func clearFilters() {
        filter = LibraryFilter()
    }

    /// Builds the Set Detail ViewModel for a tapped card from the loaded
    /// catalogue — no second fetch.
    public func setDetailViewModel(for card: SetCardModel) -> SetDetailViewModel? {
        guard let set = catalogData.sets.first(where: { $0.id == card.id }) else { return nil }
        return SetDetailViewModel(set: set, catalog: catalogData, favourites: favourites, analytics: analytics)
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
            filterOptions = FilterOptions.derive(from: loaded)
            state = allSets.isEmpty ? .empty : .loaded
        } catch {
            let catalogError = CatalogError.from(error)
            state = .failed(
                message: catalogError.errorDescription ?? "Something went wrong.",
                retryable: catalogError.isRetryable
            )
        }
    }

    /// Maps a catalogue into card models, newest first. Pure and testable.
    static func map(_ catalog: Catalog, favourites: Set<HardstyleSet.ID>) -> [SetCardModel] {
        // BUG (DebuggingLab): ascending sort surfaces the OLDEST sets first, but
        // the Library is meant to lead with the newest golden-era sets. Caught by
        // LibraryViewModelTests.test_load_success_populatesNewestFirst. See
        // DEBUGGING_LAB.md → "Reversed catalogue ordering".
        let newestFirst = catalog.sets.sorted { $0.year < $1.year }
        return SetPresenter.cards(newestFirst, in: catalog, favourites: favourites)
    }
}
