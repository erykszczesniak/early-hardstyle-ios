import Core
import DesignSystem
import Foundation
import Services

/// Drives the Set Detail screen: the primary set, its metadata and related
/// sets, backed by the already-loaded catalogue. The PLAY action is the entry
/// point the player screen (#10) hooks into.
@MainActor
@Observable
public final class SetDetailViewModel {
    private let hardstyleSet: HardstyleSet
    private let catalog: Catalog
    private let favourites: FavouritesService
    private let analytics: any Analytics
    private var favouriteIDs: Set<HardstyleSet.ID> = []

    public private(set) var card: SetCardModel
    public private(set) var related: [SetCardModel] = []

    public let djName: String
    public let genres: [String]

    public init(set: HardstyleSet, catalog: Catalog, favourites: FavouritesService, analytics: any Analytics) {
        hardstyleSet = set
        self.catalog = catalog
        self.favourites = favourites
        self.analytics = analytics
        djName = catalog.dj(for: set)?.name ?? "Unknown DJ"
        genres = catalog.genres(for: set).map(\.name)
        card = SetPresenter.card(for: set, in: catalog, isSaved: false)
    }

    public var title: String {
        hardstyleSet.title
    }

    public var youtubeID: String {
        hardstyleSet.youtubeID
    }

    public var durationText: String {
        HardstyleSet.formatDuration(seconds: hardstyleSet.durationSeconds)
    }

    /// Secondary meta line, e.g. "Defqon.1 2007 · 1:08:45".
    public var metaLine: String {
        "\(card.eventName) \(hardstyleSet.year) · \(durationText)"
    }

    public var isSaved: Bool {
        card.isSaved
    }

    /// The descriptor handed to the player.
    public var nowPlaying: NowPlaying {
        NowPlaying(
            title: hardstyleSet.title,
            subtitle: metaLine,
            artworkURL: card.thumbnailURL,
            youtubeID: hardstyleSet.youtubeID
        )
    }

    /// Builds a player ViewModel backed by the official YouTube engine.
    public func makePlayerViewModel() -> PlayerViewModel {
        PlayerViewModel(nowPlaying: nowPlaying, player: WebKitYouTubePlayer(), analytics: analytics)
    }

    public func onAppear() async {
        analytics.trackScreenView("Set Detail")
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

    public func toggleSavePrimary() async {
        await toggleSave(hardstyleSet.id)
    }

    /// Builds the detail ViewModel for a tapped related set, reusing the same
    /// catalogue and collaborators.
    public func detailViewModel(for relatedCard: SetCardModel) -> SetDetailViewModel? {
        guard let relatedSet = catalog.sets.first(where: { $0.id == relatedCard.id }) else { return nil }
        return SetDetailViewModel(set: relatedSet, catalog: catalog, favourites: favourites, analytics: analytics)
    }

    private func rebuild() {
        card = SetPresenter.card(for: hardstyleSet, in: catalog, isSaved: favouriteIDs.contains(hardstyleSet.id))
        related = SetPresenter.cards(
            Self.related(to: hardstyleSet, in: catalog),
            in: catalog,
            favourites: favouriteIDs
        )
    }

    /// Related sets: same event or same DJ, excluding this one, newest first.
    /// Pure and testable (`nonisolated` so it runs off the main actor too).
    nonisolated static func related(to hardstyleSet: HardstyleSet, in catalog: Catalog) -> [HardstyleSet] {
        catalog.sets
            .filter { $0.id != hardstyleSet.id && ($0.eventID == hardstyleSet.eventID || $0.djID == hardstyleSet.djID) }
            .sorted { $0.year > $1.year }
    }
}
