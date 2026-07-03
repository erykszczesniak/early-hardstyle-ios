import Core
import DesignSystem
import Foundation
import Services

/// Drives the Saved screen: the user's favourited sets, most-recently-saved
/// first. Reloads on every appearance so favourites toggled on other tabs are
/// reflected here (the favourites store is shared across screens).
@MainActor
@Observable
public final class SavedViewModel {
    private let catalog: CatalogService
    private let favourites: FavouritesService
    private let analytics: any Analytics

    public private(set) var state: ScreenState = .loading
    public private(set) var sets: [SetCardModel] = []

    private var catalogData: Catalog = .empty
    private var loadedCatalog = false

    public init(catalog: CatalogService, favourites: FavouritesService, analytics: any Analytics) {
        self.catalog = catalog
        self.favourites = favourites
        self.analytics = analytics
    }

    public func onAppear() async {
        analytics.trackScreenView("Saved")
        if loadedCatalog {
            await refreshSaved()
        } else {
            await load()
        }
    }

    public func load() async {
        state = .loading
        do {
            catalogData = try await catalog.loadCatalog()
            loadedCatalog = true
            await refreshSaved()
        } catch {
            let catalogError = (error as? CatalogError) ?? .unknown
            state = .failed(
                message: catalogError.errorDescription ?? "Something went wrong.",
                retryable: catalogError.isRetryable
            )
        }
    }

    public func retry() async {
        await load()
    }

    public func toggleSave(_ id: HardstyleSet.ID) async {
        await favourites.toggle(id)
        await refreshSaved()
    }

    /// Builds the Set Detail ViewModel for a tapped card from the loaded catalogue.
    public func setDetailViewModel(for card: SetCardModel) -> SetDetailViewModel? {
        guard let set = catalogData.sets.first(where: { $0.id == card.id }) else { return nil }
        return SetDetailViewModel(set: set, catalog: catalogData, favourites: favourites, analytics: analytics)
    }

    /// Re-maps the saved sets from the shared favourites store, preserving
    /// most-recently-saved-first order.
    private func refreshSaved() async {
        let favourited = await favourites.all()
        let ids = Set(favourited.map(\.setID))
        let rank = Dictionary(uniqueKeysWithValues: favourited.enumerated().map { ($1.setID, $0) })

        let savedSets = catalogData.sets
            .filter { ids.contains($0.id) }
            .sorted { (rank[$0.id] ?? .max) < (rank[$1.id] ?? .max) }

        sets = SetPresenter.cards(savedSets, in: catalogData, favourites: ids)
        state = sets.isEmpty ? .empty : .loaded
    }
}
