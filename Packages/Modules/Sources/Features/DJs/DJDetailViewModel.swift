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
    private let favourites: FavouritesService
    private let analytics: any Analytics
    private var favouriteIDs: Set<HardstyleSet.ID> = []

    public private(set) var sets: [SetCardModel] = []

    public init(dj: Dj, catalog: Catalog, favourites: FavouritesService, analytics: any Analytics) {
        self.dj = dj
        self.catalog = catalog
        self.favourites = favourites
        self.analytics = analytics
    }

    public var setCount: Int {
        catalog.sets(byDJ: dj.id).count
    }

    public var subtitle: String {
        DJCardModel.subtitle(country: dj.country, setCount: setCount)
    }

    public func onAppear() async {
        analytics.trackScreenView("DJ Detail")
        favouriteIDs = await favourites.favouriteIDs()
        rebuild()
    }

    public func toggleSave(_ id: HardstyleSet.ID) async {
        let nowSaved = await favourites.toggle(id)
        if nowSaved {
            favouriteIDs.insert(id)
        } else {
            favouriteIDs.remove(id)
        }
        rebuild()
    }

    /// Builds the Set Detail ViewModel for a tapped set from the same catalogue.
    public func setDetailViewModel(for card: SetCardModel) -> SetDetailViewModel? {
        guard let set = catalog.sets.first(where: { $0.id == card.id }) else { return nil }
        return SetDetailViewModel(set: set, catalog: catalog, favourites: favourites, analytics: analytics)
    }

    private func rebuild() {
        sets = SetPresenter.cards(catalog.sets(byDJ: dj.id), in: catalog, favourites: favouriteIDs)
    }
}
