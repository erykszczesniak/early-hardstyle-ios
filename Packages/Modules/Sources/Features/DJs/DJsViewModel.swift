import Core
import DesignSystem
import Foundation
import Services

/// Drives the DJs grid: loads the catalogue, derives DJ cards with set counts,
/// and exposes search — all as explicit state.
@MainActor
@Observable
public final class DJsViewModel {
    private let catalog: CatalogService
    private let favourites: FavouritesStore
    private let analytics: any Analytics

    public private(set) var state: ScreenState = .loading
    public var searchQuery: String = ""

    private var catalogData: Catalog = .empty
    private var allDJs: [DJCardModel] = []

    public init(catalog: CatalogService, favourites: FavouritesStore, analytics: any Analytics) {
        self.catalog = catalog
        self.favourites = favourites
        self.analytics = analytics
    }

    public var visibleDJs: [DJCardModel] {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return allDJs }
        return allDJs.filter {
            $0.name.lowercased().contains(query) || $0.country.lowercased().contains(query)
        }
    }

    public var hasNoResults: Bool {
        state == .loaded && !allDJs.isEmpty && visibleDJs.isEmpty
    }

    public func onAppear() async {
        analytics.trackScreenView("DJs")
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

    /// Builds the detail ViewModel for a tapped DJ from the already-loaded
    /// catalogue — no second network round-trip.
    public func detailViewModel(for card: DJCardModel) -> DJDetailViewModel? {
        guard let dj = catalogData.djs.first(where: { $0.id == card.id }) else { return nil }
        return DJDetailViewModel(dj: dj, catalog: catalogData, favourites: favourites, analytics: analytics)
    }

    private func fetch() async {
        do {
            let loaded = try await catalog.loadCatalog()
            catalogData = loaded
            allDJs = Self.map(loaded)
            state = allDJs.isEmpty ? .empty : .loaded
        } catch {
            let catalogError = CatalogError.from(error)
            state = .failed(
                message: catalogError.errorDescription ?? "Something went wrong.",
                retryable: catalogError.isRetryable
            )
        }
    }

    /// Maps the catalogue's DJs into cards with set counts, alphabetically.
    /// Pure and testable.
    static func map(_ catalog: Catalog) -> [DJCardModel] {
        catalog.djs
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            .map { dj in
                DJCardModel(
                    id: dj.id,
                    name: dj.name,
                    country: dj.country,
                    setCount: catalog.sets(byDJ: dj.id).count,
                    imageURL: dj.imageURL
                )
            }
    }
}
