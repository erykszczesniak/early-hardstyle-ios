import Core
import DesignSystem

/// Maps domain sets onto the DesignSystem `SetCardModel`, resolving event and
/// genre names against a catalogue. The single place this mapping lives, shared
/// by every screen that shows set cards. Pure and testable.
enum SetPresenter {
    static func card(for set: HardstyleSet, in catalog: Catalog, isSaved: Bool) -> SetCardModel {
        SetCardModel(
            id: set.id,
            title: set.title,
            eventName: catalog.event(for: set)?.name ?? L10n.Common.unknownEvent,
            year: set.year,
            durationSeconds: set.durationSeconds,
            genres: catalog.genres(for: set).map(\.name),
            thumbnailURL: set.thumbnailURL,
            isSaved: isSaved,
            bpm: set.bpm
        )
    }

    /// The playback descriptor for a set.
    static func nowPlaying(for set: HardstyleSet, in catalog: Catalog) -> NowPlaying {
        let event = catalog.event(for: set)?.name ?? L10n.Common.unknownEvent
        return NowPlaying(
            setID: set.id,
            title: set.title,
            subtitle: "\(event) \(set.year)",
            artworkURL: set.thumbnailURL,
            source: set.audioSource.map { .audio(url: $0) } ?? .youtube(id: set.youtubeID)
        )
    }

    /// Maps the given sets, in order, resolving saved state from `favourites`.
    static func cards(
        _ sets: [HardstyleSet],
        in catalog: Catalog,
        favourites: Set<HardstyleSet.ID>
    ) -> [SetCardModel] {
        sets.map { card(for: $0, in: catalog, isSaved: favourites.contains($0.id)) }
    }
}
