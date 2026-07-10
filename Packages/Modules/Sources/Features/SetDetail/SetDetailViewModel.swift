import Core
import DesignSystem
import Foundation
import Services

/// Drives the Set Detail screen: the primary set, its metadata and related
/// sets, backed by the already-loaded catalogue. The PLAY action is the entry
/// point the player screen hooks into.
@MainActor
@Observable
public final class SetDetailViewModel {
    private let hardstyleSet: HardstyleSet
    private let catalog: Catalog
    private let favourites: FavouritesStore
    private let analytics: any Analytics

    public let djName: String
    public let genres: [String]

    public init(set: HardstyleSet, catalog: Catalog, favourites: FavouritesStore, analytics: any Analytics) {
        hardstyleSet = set
        self.catalog = catalog
        self.favourites = favourites
        self.analytics = analytics
        djName = catalog.dj(for: set)?.name ?? L10n.Common.unknownDJ
        genres = catalog.genres(for: set).map(\.name)
    }

    /// The primary set's card, with saved state read live from the shared store.
    public var card: SetCardModel {
        SetPresenter.card(for: hardstyleSet, in: catalog, isSaved: favourites.isFavourite(hardstyleSet.id))
    }

    /// Related sets, with saved state read live from the shared store.
    public var related: [SetCardModel] {
        SetPresenter.cards(Self.related(to: hardstyleSet, in: catalog), in: catalog, favourites: favourites.ids)
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

    /// Secondary meta line, e.g. "Defqon.1 2007 · 1:08:45 · 150 BPM".
    public var metaLine: String {
        var line = "\(card.eventName) \(hardstyleSet.year) · \(durationText)"
        if let bpm = hardstyleSet.bpm {
            line += " · \(L10n.SetDetail.bpm(bpm))"
        }
        return line
    }

    public var isSaved: Bool {
        favourites.isFavourite(hardstyleSet.id)
    }

    /// The set's ordered tracklist, empty when none is known.
    public var tracklist: [SetTrack] {
        hardstyleSet.tracks
    }

    /// The descriptor handed to the player.
    public var nowPlaying: NowPlaying {
        SetPresenter.nowPlaying(for: hardstyleSet, in: catalog)
    }

    /// The play queue starting with this set, followed by its related sets, so
    /// autoplay flows naturally into similar sets.
    public func makeQueue() -> [NowPlaying] {
        ([hardstyleSet] + Self.related(to: hardstyleSet, in: catalog))
            .map { SetPresenter.nowPlaying(for: $0, in: catalog) }
    }

    public func onAppear() async {
        analytics.trackScreenView(.setDetail)
        await favourites.load()
    }

    public func toggleSave(_ id: HardstyleSet.ID) async {
        await favourites.toggle(id)
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

    /// Related sets: same event or same DJ, excluding this one, newest first.
    /// Pure and testable (`nonisolated` so it runs off the main actor too).
    nonisolated static func related(to hardstyleSet: HardstyleSet, in catalog: Catalog) -> [HardstyleSet] {
        catalog.sets
            .filter { $0.id != hardstyleSet.id && ($0.eventID == hardstyleSet.eventID || $0.djID == hardstyleSet.djID) }
            .sorted { $0.year > $1.year }
    }
}
