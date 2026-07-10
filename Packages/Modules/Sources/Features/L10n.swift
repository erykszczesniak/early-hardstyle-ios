import Foundation

/// Typed accessors for the module's user-facing copy. English values live here
/// as `defaultValue`s and in `Resources/Localizable.xcstrings` — UI code never
/// hardcodes user-facing strings, so adding a language is a catalog-only change.
///
/// Deliberately NOT localized: analytics screen names (identifiers), seed
/// content (proper nouns), the brand wordmark, and the debug styleguide.
enum L10n {
    enum Tab {
        static let library = String(localized: "tab.library", defaultValue: "Library", bundle: .module)
        static let djs = String(localized: "tab.djs", defaultValue: "DJs", bundle: .module)
        static let saved = String(localized: "tab.saved", defaultValue: "Saved", bundle: .module)
        static let tracks = String(localized: "tab.tracks", defaultValue: "Tracks", bundle: .module)
    }

    enum Library {
        static let title = String(localized: "library.title", defaultValue: "EARLYHS", bundle: .module)
        static let searchPrompt = String(
            localized: "library.search.prompt", defaultValue: "Search sets, DJs, events", bundle: .module
        )
        static let heroEyebrow = String(
            localized: "library.hero.eyebrow",
            defaultValue: "THE GOLDEN ERA",
            bundle: .module
        )
        static let heroMeta = String(
            localized: "library.hero.meta", defaultValue: "1999–2007 · raw power", bundle: .module
        )
        static let heroPlay = String(localized: "library.hero.play", defaultValue: "Play latest", bundle: .module)
        static let heroContinue = String(
            localized: "library.hero.continue", defaultValue: "Continue listening", bundle: .module
        )
        static let emptyTitle = String(localized: "library.empty.title", defaultValue: "No sets yet", bundle: .module)
        static let noResultsTitle = String(
            localized: "library.noResults.title",
            defaultValue: "No results",
            bundle: .module
        )
        static let noResultsMessage = String(
            localized: "library.noResults.message",
            defaultValue: "No sets match your search or filters.",
            bundle: .module
        )
        static let clearFilters = String(
            localized: "library.noResults.clear",
            defaultValue: "Clear filters",
            bundle: .module
        )
        static let filtersA11y = String(localized: "library.filters.a11y", defaultValue: "Filters", bundle: .module)
        static let jumpBackIn = String(localized: "library.jumpBackIn", defaultValue: "Jump back in", bundle: .module)

        static func filtersActiveA11y(_ count: Int) -> String {
            String(localized: "library.filters.a11y.active", defaultValue: "Filters, \(count) active", bundle: .module)
        }
    }

    enum Filters {
        static let title = String(localized: "filters.title", defaultValue: "Filters", bundle: .module)
        static let clear = String(localized: "filters.clear", defaultValue: "Clear", bundle: .module)
        static let done = String(localized: "filters.done", defaultValue: "Done", bundle: .module)
        static let year = String(localized: "filters.year", defaultValue: "Year", bundle: .module)
        static let event = String(localized: "filters.event", defaultValue: "Event", bundle: .module)
        static let genre = String(localized: "filters.genre", defaultValue: "Genre", bundle: .module)
        static let country = String(localized: "filters.country", defaultValue: "Country", bundle: .module)
    }

    enum DJs {
        static let title = String(localized: "djs.title", defaultValue: "DJs", bundle: .module)
        static let searchPrompt = String(localized: "djs.search.prompt", defaultValue: "Search DJs", bundle: .module)
        static let emptyTitle = String(localized: "djs.empty.title", defaultValue: "No DJs yet", bundle: .module)
        static let noResultsTitle = String(
            localized: "djs.noResults.title",
            defaultValue: "No results",
            bundle: .module
        )
        static let unavailable = String(localized: "djs.unavailable", defaultValue: "DJ unavailable", bundle: .module)

        static func noResultsMessage(_ query: String) -> String {
            String(localized: "djs.noResults.message", defaultValue: "No DJs match “\(query)”.", bundle: .module)
        }
    }

    enum Tracks {
        static let title = String(localized: "tracks.title", defaultValue: "Tracks", bundle: .module)
        static let emptyTitle = String(localized: "tracks.empty.title", defaultValue: "No tracks yet", bundle: .module)
        static let sortLabel = String(localized: "tracks.sort.label", defaultValue: "Sort", bundle: .module)
        static let sortBPM = String(localized: "tracks.sort.bpm", defaultValue: "BPM", bundle: .module)
        static let sortNewest = String(localized: "tracks.sort.newest", defaultValue: "Newest", bundle: .module)
        static let sortAlphabetical = String(
            localized: "tracks.sort.alphabetical", defaultValue: "A–Z", bundle: .module
        )
    }

    enum Search {
        static let prompt = String(
            localized: "search.prompt",
            defaultValue: "Search sets, DJs, events",
            bundle: .module
        )
        static let cancel = String(localized: "search.cancel", defaultValue: "Cancel", bundle: .module)
        static let recent = String(localized: "search.recent", defaultValue: "Recent searches", bundle: .module)
        static let sets = String(localized: "search.sets", defaultValue: "Sets", bundle: .module)
        static let djs = String(localized: "search.djs", defaultValue: "DJs", bundle: .module)
        static let events = String(localized: "search.events", defaultValue: "Events", bundle: .module)
        static let noResultsTitle = String(
            localized: "search.noResults.title", defaultValue: "No results", bundle: .module
        )

        static func noResultsMessage(_ query: String) -> String {
            String(localized: "search.noResults.message", defaultValue: "Nothing matches “\(query)”.", bundle: .module)
        }
    }

    enum Saved {
        static let title = String(localized: "saved.title", defaultValue: "Saved", bundle: .module)
        static let emptyTitle = String(
            localized: "saved.empty.title",
            defaultValue: "Nothing saved yet",
            bundle: .module
        )
        static let emptyMessage = String(
            localized: "saved.empty.message", defaultValue: "Tap ♥ on any set to keep it here.", bundle: .module
        )
        static let browseLibrary = String(
            localized: "saved.empty.browse",
            defaultValue: "Browse Library",
            bundle: .module
        )
    }

    enum SetDetail {
        static let play = String(localized: "setDetail.play", defaultValue: "Play", bundle: .module)
        static let related = String(localized: "setDetail.related", defaultValue: "Related sets", bundle: .module)
        static let tracklist = String(localized: "setDetail.tracklist", defaultValue: "Tracklist", bundle: .module)
        static let playerComingSoon = String(
            localized: "setDetail.playerComingSoon", defaultValue: "Player coming soon", bundle: .module
        )

        static func bpm(_ value: Int) -> String {
            String(localized: "setDetail.bpm", defaultValue: "\(value) BPM", bundle: .module)
        }
    }

    enum Player {
        static let close = String(localized: "player.close", defaultValue: "Close player", bundle: .module)
        static let queue = String(localized: "player.queue", defaultValue: "Queue", bundle: .module)
        static let play = String(localized: "player.play", defaultValue: "Play", bundle: .module)
        static let pause = String(localized: "player.pause", defaultValue: "Pause", bundle: .module)
        static let replay = String(localized: "player.replay", defaultValue: "Replay", bundle: .module)
        static let previous = String(localized: "player.previous", defaultValue: "Previous", bundle: .module)
        static let next = String(localized: "player.next", defaultValue: "Next", bundle: .module)
        static let attribution = String(
            localized: "player.attribution",
            defaultValue: "Video played via the official YouTube player",
            bundle: .module
        )
        static let errorNotEmbeddable = String(
            localized: "player.error.notEmbeddable",
            defaultValue: "The video's owner doesn't allow it to play inside apps. Try another set.",
            bundle: .module
        )
        static let errorUnavailable = String(
            localized: "player.error.unavailable", defaultValue: "This video is unavailable.", bundle: .module
        )
        static let errorGeneric = String(
            localized: "player.error.generic", defaultValue: "Playback failed. Please try again.", bundle: .module
        )
    }

    enum Queue {
        static let title = String(localized: "queue.title", defaultValue: "Queue", bundle: .module)
        static let autoplayNext = String(
            localized: "queue.autoplayNext",
            defaultValue: "Autoplay next",
            bundle: .module
        )
        static let upNext = String(localized: "queue.upNext", defaultValue: "Up next", bundle: .module)
        static let done = String(localized: "queue.done", defaultValue: "Done", bundle: .module)
    }

    enum Common {
        static let catalogueEmptyMessage = String(
            localized: "common.catalogueEmpty.message",
            defaultValue: "The catalogue is empty right now. Pull to refresh.",
            bundle: .module
        )
        static let genericError = String(
            localized: "common.error.generic", defaultValue: "Something went wrong.", bundle: .module
        )
        static let unknownEvent = String(
            localized: "common.unknownEvent",
            defaultValue: "Unknown event",
            bundle: .module
        )
        static let unknownDJ = String(localized: "common.unknownDJ", defaultValue: "Unknown DJ", bundle: .module)
    }
}
