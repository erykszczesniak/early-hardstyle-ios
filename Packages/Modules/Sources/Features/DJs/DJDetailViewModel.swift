import Core
import DesignSystem
import Foundation
import Services

/// Drives a single DJ's detail screen: the DJ's sets (newest first) with saved
/// state, backed by the already-loaded catalogue.
@MainActor
@Observable
public final class DJDetailViewModel {
    public let dj: Dj

    private let catalog: Catalog
    private let favourites: FavouritesStore
    private let analytics: any Analytics

    public init(dj: Dj, catalog: Catalog, favourites: FavouritesStore, analytics: any Analytics) {
        self.dj = dj
        self.catalog = catalog
        self.favourites = favourites
        self.analytics = analytics
    }

    /// The DJ's sets, newest first, with saved state read live from the shared
    /// favourites store.
    public var sets: [SetCardModel] {
        SetPresenter.cards(catalog.sets(byDJ: dj.id), in: catalog, favourites: favourites.ids)
    }

    public var setCount: Int {
        catalog.sets(byDJ: dj.id).count
    }

    public var subtitle: String {
        DJCardModel.subtitle(country: dj.country, setCount: setCount)
    }

    public func onAppear() async {
        analytics.trackScreenView(.djDetail)
        await favourites.load()
    }

    public func toggleSave(_ id: HardstyleSet.ID) async {
        await favourites.toggle(id)
    }

    /// Builds the Set Detail ViewModel for a tapped set from the same catalogue.
    public func setDetailViewModel(for card: SetCardModel) -> SetDetailViewModel? {
        guard let set = catalog.sets.first(where: { $0.id == card.id }) else { return nil }
        return SetDetailViewModel(set: set, catalog: catalog, favourites: favourites, analytics: analytics)
    }
}
