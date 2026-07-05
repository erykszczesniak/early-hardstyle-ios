import Core
import DesignSystem
import Foundation
import Services

/// Drives the global search cover: one query, grouped results over the whole
/// catalogue (sets / DJs / events) and persisted recent phrases.
@MainActor
@Observable
public final class SearchViewModel {
    public struct Results: Equatable {
        public var sets: [SetCardModel] = []
        public var djs: [DJCardModel] = []
        public var events: [Event] = []

        public var isEmpty: Bool {
            sets.isEmpty && djs.isEmpty && events.isEmpty
        }
    }

    private let catalog: CatalogService
    private let favourites: FavouritesStore
    private let recents: RecentSearchesStoring
    private let analytics: any Analytics

    public var query: String = ""
    public private(set) var recentPhrases: [String] = []
    private var catalogData: Catalog = .empty

    public init(
        catalog: CatalogService,
        favourites: FavouritesStore,
        recents: RecentSearchesStoring,
        analytics: any Analytics
    ) {
        self.catalog = catalog
        self.favourites = favourites
        self.recents = recents
        self.analytics = analytics
    }

    public func onAppear() async {
        analytics.trackScreenView(.search)
        recentPhrases = recents.all()
        if catalogData.sets.isEmpty {
            catalogData = await (try? catalog.loadCatalog()) ?? .empty
            await favourites.load()
        }
    }

    /// Grouped matches for the current query (empty query → empty results).
    public var results: Results {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !needle.isEmpty else { return Results() }

        var results = Results()
        results.sets = catalogData.sets
            .filter { setMatches($0, needle: needle) }
            .sorted { $0.year > $1.year }
            .map { SetPresenter.card(for: $0, in: catalogData, isSaved: favourites.isFavourite($0.id)) }
        results.djs = catalogData.djs
            .filter { $0.name.lowercased().contains(needle) || $0.country.lowercased().contains(needle) }
            .map { dj in
                DJCardModel(
                    id: dj.id,
                    name: dj.name,
                    country: dj.country,
                    setCount: catalogData.sets(byDJ: dj.id).count,
                    imageURL: dj.imageURL
                )
            }
        results.events = catalogData.events.filter { $0.name.lowercased().contains(needle) }
        return results
    }

    private func setMatches(_ set: HardstyleSet, needle: String) -> Bool {
        set.title.lowercased().contains(needle)
            || (catalogData.dj(for: set)?.name.lowercased().contains(needle) ?? false)
            || (catalogData.event(for: set)?.name.lowercased().contains(needle) ?? false)
    }

    public func toggleSave(_ id: HardstyleSet.ID) async {
        await favourites.toggle(id)
    }

    /// Remembers the current phrase (called when the user commits or taps a result).
    public func rememberQuery() {
        recents.add(query)
        recentPhrases = recents.all()
    }

    public func useRecent(_ phrase: String) {
        query = phrase
    }

    // MARK: Navigation factories (from the already-loaded catalogue)

    public func setDetailViewModel(for card: SetCardModel) -> SetDetailViewModel? {
        guard let set = catalogData.sets.first(where: { $0.id == card.id }) else { return nil }
        return SetDetailViewModel(set: set, catalog: catalogData, favourites: favourites, analytics: analytics)
    }

    public func djDetailViewModel(for card: DJCardModel) -> DJDetailViewModel? {
        guard let dj = catalogData.djs.first(where: { $0.id == card.id }) else { return nil }
        return DJDetailViewModel(dj: dj, catalog: catalogData, favourites: favourites, analytics: analytics)
    }

    /// The sets of a tapped event, newest first.
    public func sets(for event: Event) -> [SetCardModel] {
        let sets = catalogData.sets.filter { $0.eventID == event.id }.sorted { $0.year > $1.year }
        return SetPresenter.cards(sets, in: catalogData, favourites: favourites.ids)
    }
}
