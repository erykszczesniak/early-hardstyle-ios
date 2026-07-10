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
    private let favourites: FavouritesStore
    private let progress: PlaybackProgressStoring
    private let recents: RecentSearchesStoring
    private let analytics: any Analytics

    public private(set) var state: LibraryState = .loading
    public var filter = LibraryFilter()
    public private(set) var filterOptions: FilterOptions = .empty

    private var catalogData: Catalog = .empty
    /// Newest-first domain sets; cards derive from these + the favourites store,
    /// so saved state is always live (single source of truth).
    private var sortedSets: [HardstyleSet] = []

    public init(
        catalog: CatalogService,
        favourites: FavouritesStore,
        progress: PlaybackProgressStoring,
        recents: RecentSearchesStoring,
        analytics: any Analytics
    ) {
        self.catalog = catalog
        self.favourites = favourites
        self.progress = progress
        self.recents = recents
        self.analytics = analytics
    }

    /// All cards, newest first, with saved state read live from the store.
    private var allSets: [SetCardModel] {
        SetPresenter.cards(sortedSets, in: catalogData, favourites: favourites.ids)
    }

    /// Sets matching the active filter (year/event/genre/country). Free-text
    /// search lives in the global Search cover.
    public var visibleSets: [SetCardModel] {
        guard !filter.isEmpty else { return allSets }
        let allowed = filter.matchingIDs(in: catalogData)
        return allSets.filter { allowed.contains($0.id) }
    }

    /// True when the catalogue has sets but the active filter hides them all.
    public var hasNoResults: Bool {
        state == .loaded && !allSets.isEmpty && visibleSets.isEmpty
    }

    /// Number of selected filter values, for the toolbar badge.
    public var activeFilterCount: Int {
        filter.activeCount
    }

    /// Whether any refining (filtering) is currently applied.
    public var isRefining: Bool {
        !filter.isEmpty
    }

    public func clearFilters() {
        filter = LibraryFilter()
    }

    /// Builds the global-search ViewModel (the cover owns its own catalogue load).
    public func makeSearchViewModel() -> SearchViewModel {
        SearchViewModel(catalog: catalog, favourites: favourites, recents: recents, analytics: analytics)
    }

    /// Builds the Set Detail ViewModel for a tapped card from the loaded
    /// catalogue — no second fetch.
    public func setDetailViewModel(for card: SetCardModel) -> SetDetailViewModel? {
        guard let set = catalogData.sets.first(where: { $0.id == card.id }) else { return nil }
        return SetDetailViewModel(set: set, catalog: catalogData, favourites: favourites, analytics: analytics)
    }

    /// One partially-listened set on the "Jump back in" rail.
    public struct ResumeEntry: Identifiable {
        public let card: SetCardModel
        public let fraction: Double
        public let nowPlaying: NowPlaying

        public var id: String {
            card.id
        }
    }

    /// Bumped whenever saved playback progress may have changed (collapsing
    /// the player, switching tracks). The progress store itself is not
    /// observable, so reading this in `jumpBackIn` is what makes SwiftUI
    /// re-render the rail — without it the just-played set only appeared
    /// after an unrelated re-render or an app relaunch.
    private var progressVersion = 0

    /// Call when playback state changed so the rail re-reads saved progress.
    public func refreshProgress() {
        progressVersion += 1
    }

    /// Partially-listened sets, most recent first — the "Jump back in" rail.
    public var jumpBackIn: [ResumeEntry] {
        _ = progressVersion // observable dependency; see `refreshProgress`
        return progress.recent(limit: 6).compactMap { entry in
            guard let set = catalogData.sets.first(where: { $0.id == entry.id }) else { return nil }
            return ResumeEntry(
                card: SetPresenter.card(for: set, in: catalogData, isSaved: favourites.isFavourite(set.id)),
                fraction: entry.position.fraction,
                nowPlaying: SetPresenter.nowPlaying(for: set, in: catalogData)
            )
        }
    }

    /// The play queue for resuming a "Jump back in" entry: the resumed set
    /// first, then its related sets — the same shape Set Detail plays, so
    /// next/previous and autoplay keep working from a resume.
    public func resumeQueue(for entry: ResumeEntry) -> [NowPlaying] {
        guard let set = catalogData.sets.first(where: { $0.id == entry.id }) else {
            return [entry.nowPlaying]
        }
        return ([set] + SetDetailViewModel.related(to: set, in: catalogData))
            .map { SetPresenter.nowPlaying(for: $0, in: catalogData) }
    }

    /// The newest set, surfaced by the hero's "Play latest" action.
    public var latestSet: SetCardModel? {
        allSets.first
    }

    /// What the hero's "Play latest" opens: the set the listener most recently
    /// played (so the button continues their session), falling back to the
    /// newest set in the catalogue when nothing has been played yet.
    public var heroSet: SetCardModel? {
        jumpBackIn.first?.card ?? latestSet
    }

    public func onAppear() async {
        analytics.trackScreenView(.library)
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
        await favourites.toggle(id)
        // Cards derive from the store, so no local reconciliation is needed.
    }

    private func fetch() async {
        do {
            let loaded = try await catalog.loadCatalog()
            catalogData = loaded
            await favourites.load()
            // Descending sort so the newest golden-era sets lead.
            sortedSets = loaded.sets.sorted { $0.year > $1.year }
            filterOptions = FilterOptions.derive(from: loaded)
            state = sortedSets.isEmpty ? .empty : .loaded
        } catch {
            let catalogError = CatalogError.from(error)
            state = .failed(
                message: catalogError.errorDescription ?? L10n.Common.genericError,
                retryable: catalogError.isRetryable
            )
        }
    }
}
