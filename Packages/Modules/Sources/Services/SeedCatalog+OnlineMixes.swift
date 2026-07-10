import Core
import Foundation

/// Channel-curated classics mixes: full YouTube uploads with known tracklists,
/// seeded alongside the event sets. Kept in its own file so `SeedCatalog.swift`
/// stays within lint budgets. Same rules as the main seed — official uploads
/// only, artwork derived from YouTube thumbnails.
extension SeedCatalog {
    static let mixDJs: [Dj] = [
        Dj(
            id: "hardstyleofchoice",
            name: "Hardstyleofchoice",
            country: "Online",
            imageURL: avatar("ByYn0U4mrtY"),
            bio: "Curator channel keeping the early-hardstyle flame alive with classics mixes."
        ),
        Dj(
            id: "last-joker",
            name: "Last JoKeR",
            country: "Online",
            imageURL: avatar("Lk_qIZsuknc"),
            bio: "Polanski “Last JoKeR” Quentin — oldschool hardstyle megamixes."
        )
    ]

    static let mixEvents: [Event] = [
        Event(id: "youtube-mix", name: "YouTube Mix", country: "Online")
    ]

    static let mixSets: [HardstyleSet] = [
        HardstyleSet(
            id: "hoc-energy-mix",
            title: "Early Hardstyle & Oldschool Energy Mix",
            djID: "hardstyleofchoice",
            eventID: "youtube-mix",
            year: 2019,
            durationSeconds: 4343,
            youtubeID: "ByYn0U4mrtY",
            genreIDs: ["early-hardstyle", "reverse-bass"],
            bpm: 150
            // The known tracklist for this mix has no timestamps, so its tracks
            // are seeded as standalone singles instead (SeedCatalog+SingleTracks).
        ),
        HardstyleSet(
            id: "hoc-oldschool-resurrection",
            title: "Oldschool Resurrection",
            djID: "hardstyleofchoice",
            eventID: "youtube-mix",
            year: 2024,
            durationSeconds: 3563,
            youtubeID: "MN--YMQ14Ik",
            genreIDs: ["early-hardstyle"],
            bpm: 148,
            tracklist: resurrectionTracklist
        ),
        HardstyleSet(
            id: "ljq-oldschool-revolution",
            title: "Oldschool Revolution",
            djID: "last-joker",
            eventID: "youtube-mix",
            year: 2016,
            durationSeconds: 2369,
            youtubeID: "Lk_qIZsuknc",
            genreIDs: ["early-hardstyle"],
            bpm: 145,
            tracklist: revolutionTracklist
        )
    ]

    private static func track(_ number: Int, _ title: String, at startSeconds: Int? = nil) -> SetTrack {
        SetTrack(number: number, title: title, startSeconds: startSeconds)
    }

    private static let resurrectionTracklist: [SetTrack] = [
        track(1, "Intro: Headhunterz - Back In The Days", at: 0),
        track(2, "Blademasterz - MasterBlade", at: 47),
        track(3, "Zany - Skyhigh (TBY RMX)", at: 201),
        track(4, "Technoboy - Raver's Rules (Prophet Remix)", at: 366),
        track(5, "DJ Isaac - Backstage", at: 436),
        track(6, "Zerovision - Overdrive (Scantraxx Remix)", at: 578),
        track(7, "Zany - Pillz", at: 722),
        track(8, "Showtek - Puta Madre", at: 948),
        track(9, "Pavo & Zany - SEX", at: 1033),
        track(10, "Da Bootleggers - Bitches N Hos", at: 1138),
        track(11, "Tuneboy - Sexbusters", at: 1267),
        track(12, "The Prophet - Emergency Call", at: 1440),
        track(13, "Zany - Science & Religion", at: 1650),
        track(14, "Southstylers - Wraow", at: 1869),
        track(15, "Technoboy - Hardventure (Tatanka Remix)", at: 2085),
        track(16, "Zany - Pure", at: 2407),
        track(17, "The Prophet vs Duro - Shizzle My Dizzzle (Beholder & Ballistic Remix)", at: 2579),
        track(18, "Duro - Cocaine MF (Oldschool Remix)", at: 2731),
        track(19, "Tatanka - Tatanka Doesn't Like The Records That You Play", at: 3107),
        track(20, "Donkey Rollers - Hardstyle Rockers", at: 3254),
        track(21, "Walt - Let The Music Play", at: 3382)
    ]

    private static let revolutionTracklist: [SetTrack] = [
        track(1, "Zatox & Zany - Oldskool", at: 0),
        track(2, "The Prophet ft. Wildstylez - Cold Rockking (Gostosa Remix)", at: 3),
        track(3, "Bruno Power - The Saint (DJ Yev Edit)", at: 230),
        track(4, "Geck-O - Respect Mah Clap", at: 311),
        track(5, "Showtek vs The Prophet & Heady - FTS (Imports Fuck This Summer Mashup)", at: 451),
        track(6, "Francesco Zeta - What Is What (Reverse Fanatic Edit)", at: 696),
        track(7, "Hardstyle Masterz - Les Phases", at: 799),
        track(8, "Scope DJ - Rock Hypnotic Again (2011 Refixx)", at: 891),
        track(9, "Zatox - Tanz Electrik (The R3bels Remix) (Reverse Fanatic Edit)", at: 1111),
        track(10, "The Pitcher ft. MC Renegade - Smack", at: 1211),
        track(11, "Air Teo - Keep da Fuck Bitch", at: 1388),
        track(12, "Scope DJ - Lockdown (Bassleader Edit)", at: 1578),
        track(13, "Francesco Zeta - Rock 'N' Rave", at: 1793),
        track(14, "Josh & Wesz - Retrospect", at: 1958),
        track(15, "Chain Reaction - Lellebel (Revisited)", at: 2171),
        track(16, "Technoboy & The Prophet ft. Shayla - Psycho Ex (Hardstyle Masterz Remix)", at: 2335)
    ]
}
