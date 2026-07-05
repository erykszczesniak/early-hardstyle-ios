import Core
import DesignSystem
import Foundation
import Services

/// How the Tracks list is ordered.
public enum TrackSort: String, CaseIterable, Sendable {
    case bpm
    case newest
    case alphabetical
}

/// Drives the Tracks screen: every track in the catalogue with its tempo,
/// re-sortable by BPM (hardest first), year or title.
@MainActor
@Observable
public final class TracksViewModel {
    private let catalog: CatalogService
    private let favourites: FavouritesStore
    private let analytics: any Analytics

    public private(set) var state: ScreenState = .loading
    public var sort: TrackSort = .bpm

    private var catalogData: Catalog = .empty

    public init(catalog: CatalogService, favourites: FavouritesStore, analytics: any Analytics) {
        self.catalog = catalog
        self.favourites = favourites
        self.analytics = analytics
    }

    /// The tracks under the active sort, saved state live from the store.
    public var tracks: [SetCardModel] {
        SetPresenter.cards(Self.sorted(catalogData.sets, by: sort), in: catalogData, favourites: favourites.ids)
    }

    public func onAppear() async {
        analytics.trackScreenView(.tracks)
        if state == .loading { await load() }
    }

    public func load() async {
        state = .loading
        do {
            catalogData = try await catalog.loadCatalog()
            await favourites.load()
            state = catalogData.sets.isEmpty ? .empty : .loaded
        } catch {
            let catalogError = CatalogError.from(error)
            state = .failed(
                message: catalogError.errorDescription ?? L10n.Common.genericError,
                retryable: catalogError.isRetryable
            )
        }
    }

    public func retry() async {
        await load()
    }

    /// Builds the Set Detail ViewModel for a tapped row from the loaded catalogue.
    public func setDetailViewModel(for card: SetCardModel) -> SetDetailViewModel? {
        guard let set = catalogData.sets.first(where: { $0.id == card.id }) else { return nil }
        return SetDetailViewModel(set: set, catalog: catalogData, favourites: favourites, analytics: analytics)
    }

    /// Pure, testable ordering. BPM sorts hardest-first (unknown tempos last);
    /// ties break by title so the order is deterministic.
    nonisolated static func sorted(_ sets: [HardstyleSet], by sort: TrackSort) -> [HardstyleSet] {
        switch sort {
        case .bpm:
            sets.sorted { lhs, rhs in
                switch (lhs.bpm, rhs.bpm) {
                case let (lhsBPM?, rhsBPM?) where lhsBPM != rhsBPM: lhsBPM > rhsBPM
                case (.some, .none): true
                case (.none, .some): false
                default: lhs.title < rhs.title
                }
            }
        case .newest:
            sets.sorted {
                if $0.year != $1.year { $0.year > $1.year } else { $0.title < $1.title }
            }
        case .alphabetical:
            sets.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        }
    }
}
