import Core
import Foundation
import Services

/// The single observable source of truth for saved sets (audit finding 4.1).
///
/// Wraps the persistent `FavouritesService` and exposes the saved-id set as
/// `@Observable` state, so every screen (cards, Saved tab, mini-player) reads
/// and toggles through **one** instance and updates live — no per-ViewModel
/// caches reconciled only `onAppear`.
@MainActor
@Observable
public final class FavouritesStore {
    private let service: FavouritesService

    /// The currently-saved set ids. Views/ViewModels derive saved state from
    /// this; it changes only through `load()`/`toggle(_:)`.
    public private(set) var ids: Set<HardstyleSet.ID> = []

    public init(service: FavouritesService) {
        self.service = service
    }

    /// Loads the persisted ids. Idempotent; call on app start (and freely
    /// elsewhere — it just re-syncs from the service).
    public func load() async {
        ids = await service.favouriteIDs()
    }

    public func isFavourite(_ id: HardstyleSet.ID) -> Bool {
        ids.contains(id)
    }

    /// Toggles a set's saved state, persists it, and returns the new state.
    @discardableResult
    public func toggle(_ id: HardstyleSet.ID) async -> Bool {
        let nowSaved = await service.toggle(id)
        if nowSaved {
            ids.insert(id)
        } else {
            ids.remove(id)
        }
        return nowSaved
    }

    /// All favourites with their save dates, most-recently-saved first (the
    /// Saved screen's ordering).
    public func orderedFavourites() async -> [Favourite] {
        await service.all()
    }
}
