import Core
import Foundation

/// Standalone classic singles — the tracklist of the "Early Hardstyle &
/// Oldschool Energy Mix" seeded as individually playable tracks, each pointing
/// at its own YouTube upload (the mix's tracklist has no timestamps, so the
/// tracks live in the catalogue directly instead of under the set).
///
/// K-Traxx - Hardventure (Technoboy Remix) is part of that tracklist too but
/// was already seeded in `SeedCatalog.swift`, so it is not repeated here.
extension SeedCatalog {
    private static func dj(_ id: String, _ name: String, _ country: String, _ youtubeID: String) -> Dj {
        Dj(id: id, name: name, country: country, imageURL: avatar(youtubeID))
    }

    static let singleDJs: [Dj] = [
        dj("cenoginerz", "Cenoginerz", "Netherlands", "tJ7skmw0Qx0"),
        dj("erik-vee", "Erik Vee", "Netherlands", "zoPh6HJsihQ"),
        dj("hardheadz", "Hardheadz", "Netherlands", "I3G93UZkggk"),
        dj("serge-remy-martinez", "DJ Serge & DJ Remy Martinez", "Netherlands", "SWMLCZY9pzk"),
        dj("atlantic-wave", "Atlantic Wave", "Italy", "BJz8kXHg34M"),
        dj("le-brisc", "Le Brisc", "Germany", "27iv5GmaQnM"),
        dj("the-kgbs", "The KGB's", "Netherlands", "ScoBUwhv0Xc"),
        dj("psycho-hardstylers", "Psycho Hardstylers", "Italy", "LQy_aOpyEbc"),
        dj("tuneboy", "Tuneboy", "Italy", "HoXJwPZiiQk"),
        dj("dj-neil", "DJ Neil", "Spain", "Y_w1BSjBB2M"),
        dj("player-one", "Player One", "Germany", "t62hzs5CN0c"),
        dj("luca-antolini", "Luca Antolini", "Italy", "Bpf1UPrGogY"),
        dj("project-medusa-exor", "Project Medusa vs Exor", "Germany", "YGJy8trodI0"),
        dj("klubbingman", "Klubbingman", "Germany", "q3cN5JMg5Pk"),
        dj("apollo", "Apollo", "Germany", "cTPQN1awnVg"),
        dj("dj-digress", "DJ Digress", "Germany", "FfyUJOADR6o"),
        dj("dj-dean", "DJ Dean", "Germany", "3phf14UZbDs"),
        dj("dj-shredda", "DJ Shredda", "Germany", "g3HE4nqMjKY"),
        dj("uberdruck", "Überdruck", "Germany", "iTe02ZB2WkE"),
        dj("rayden", "Rayden", "Italy", "HgTwHzwj1Ng"),
        dj("max-b-grant", "Max B. Grant", "Switzerland", "q_-JYYu8g1A"),
        dj("dopeman", "Dopeman", "Netherlands", "byfTzVNgSJw"),
        dj("high-voltage", "High Voltage", "Netherlands", "5zkcAOgrvCo"),
        dj("adam-glund", "Adam & Glund", "Germany", "AEnakYioulQ"),
        dj("kai-tracid", "Kai Tracid", "Germany", "8JqvMx47wK0"),
        dj("daniele-mondello", "Daniele Mondello", "Italy", "7iicE_G0jcE"),
        dj("titanic-bros", "Titanic Bros", "Italy", "Gl32Dslpxlg"),
        dj("blutonium-boy", "Blutonium Boy", "Germany", "6tkhdcgmJAU"),
        dj("piero-zeta-manuel-es", "Piero Zeta & Manuel Es", "Italy", "kGxbQsEjbHk")
    ]

    static let singleEvents: [Event] = [
        Event(id: "classics", name: "Classics", country: "Various")
    ]

    // swiftlint:disable function_parameter_count
    /// A standalone classic single: one track, its own upload, era-approximate
    /// year and tempo, filed under the shared "Classics" shelf.
    private static func single(
        _ id: String,
        _ title: String,
        _ dj: String,
        _ year: Int,
        _ seconds: Int,
        _ youtube: String,
        bpm: Int
    ) -> HardstyleSet {
        HardstyleSet(
            id: id,
            title: title,
            djID: dj,
            eventID: "classics",
            year: year,
            durationSeconds: seconds,
            youtubeID: youtube,
            genreIDs: ["early-hardstyle"],
            bpm: bpm
        )
    }

    // swiftlint:enable function_parameter_count

    static let singleTracks: [HardstyleSet] = [
        single(
            "cenoginerz-you-like-the-bass",
            "Cenoginerz - You Like The Bass (DJ Zany Remix)",
            "cenoginerz",
            2002,
            264,
            "tJ7skmw0Qx0",
            bpm: 145
        ),
        single(
            "erik-vee-wildside",
            "Erik Vee - Wildside (Club Mix)",
            "erik-vee",
            2002,
            372,
            "zoPh6HJsihQ",
            bpm: 145
        ),
        single(
            "hardheadz-hardhouz-generation",
            "Hardheadz - Hardhouz Generation (DJ Dean Remix)",
            "hardheadz",
            2002,
            319,
            "I3G93UZkggk",
            bpm: 145
        ),
        single(
            "serge-remy-da-beat",
            "DJ Serge & DJ Remy Martinez - Da Beat (Original Mix)",
            "serge-remy-martinez",
            2002,
            176,
            "SWMLCZY9pzk",
            bpm: 145
        ),
        single(
            "atlantic-wave-the-creation",
            "Atlantic Wave - The Creation (Giada Remix)",
            "atlantic-wave",
            2003,
            442,
            "BJz8kXHg34M",
            bpm: 145
        ),
        single(
            "le-brisc-ive-got-the-power",
            "Le Brisc - I've Got The Power (Thomas Trouble Hardstyle Mix)",
            "le-brisc",
            2002,
            343,
            "27iv5GmaQnM",
            bpm: 145
        ),
        single(
            "kgbs-the-disco-fan",
            "The KGB's - The Disco Fan (Hardisco Mix)",
            "the-kgbs",
            2002,
            357,
            "ScoBUwhv0Xc",
            bpm: 145
        ),
        single(
            "psycho-hardstylers-the-game",
            "Psycho Hardstylers - The Game (Analogic Disturbance Mix)",
            "psycho-hardstylers",
            2002,
            388,
            "LQy_aOpyEbc",
            bpm: 145
        ),
        single(
            "tuneboy-demolition",
            "Tuneboy - Demolition (Technoboy Remix)",
            "tuneboy",
            2003,
            375,
            "HoXJwPZiiQk",
            bpm: 148
        ),
        single(
            "dj-neil-go-ahead",
            "DJ Neil - Go Ahead (Orange Mix)",
            "dj-neil",
            2002,
            387,
            "Y_w1BSjBB2M",
            bpm: 145
        ),
        single(
            "player-one-insomnia",
            "Player One - Insomnia (Asylum Mix)",
            "player-one",
            2002,
            467,
            "t62hzs5CN0c",
            bpm: 145
        ),
        single(
            "luca-antolini-life-is-a-mistery",
            "Luca Antolini - Life Is A Mistery",
            "luca-antolini",
            2003,
            441,
            "Bpf1UPrGogY",
            bpm: 145
        ),
        single(
            "project-medusa-exor-moonshine",
            "Project Medusa vs Exor - Moonshine (Megara vs DJ Lee Dub Remix)",
            "project-medusa-exor",
            2002,
            439,
            "YGJy8trodI0",
            bpm: 140
        ),
        single(
            "klubbingman-highway-to-the-sky",
            "Klubbingman - Highway To The Sky (Megara vs DJ Lee Remix)",
            "klubbingman",
            2003,
            389,
            "q3cN5JMg5Pk",
            bpm: 140
        ),
        single(
            "apollo-dance",
            "Apollo - Dance (Megara vs DJ Lee Remix)",
            "apollo",
            2003,
            442,
            "cTPQN1awnVg",
            bpm: 140
        ),
        single(
            "dj-digress-the-frequency",
            "DJ Digress - The Frequency (DJ Dean Remix)",
            "dj-digress",
            2002,
            389,
            "FfyUJOADR6o",
            bpm: 140
        ),
        single(
            "dj-dean-protect-your-ears",
            "DJ Dean - Protect Your Ears (Ballanation Mix)",
            "dj-dean",
            2002,
            528,
            "3phf14UZbDs",
            bpm: 140
        ),
        single(
            "dj-shredda-chainsaw",
            "DJ Shredda - Chainsaw (Crow Remix)",
            "dj-shredda",
            2003,
            411,
            "g3HE4nqMjKY",
            bpm: 148
        ),
        single(
            "uberdruck-bloody-slut",
            "Überdruck - Bloody Slut (The Crow Mix)",
            "uberdruck",
            2002,
            478,
            "iTe02ZB2WkE",
            bpm: 150
        ),
        single(
            "rayden-i-know-ur-waiting",
            "Rayden - I Know Ur Waiting (Überdruck Remix)",
            "rayden",
            2002,
            370,
            "HgTwHzwj1Ng",
            bpm: 150
        ),
        single(
            "max-b-grant-running",
            "Max B. Grant - Running (DJ Vortex Remix)",
            "max-b-grant",
            2003,
            387,
            "q_-JYYu8g1A",
            bpm: 150
        ),
        single(
            "dopeman-who-iz-your-daddy",
            "Dopeman - Who Iz Your Daddy (Original Mix)",
            "dopeman",
            2002,
            218,
            "byfTzVNgSJw",
            bpm: 145
        ),
        single(
            "high-voltage-bombs-away",
            "High Voltage - Bombs Away (Original Mix)",
            "high-voltage",
            2002,
            364,
            "5zkcAOgrvCo",
            bpm: 145
        ),
        single(
            "adam-glund-bass-core",
            "Adam & Glund - Bass Core (Mass In Orbit Remix)",
            "adam-glund",
            2002,
            504,
            "AEnakYioulQ",
            bpm: 145
        ),
        single(
            "kai-tracid-4-just-1-day",
            "Kai Tracid - 4 Just 1 Day (Derb Remix)",
            "kai-tracid",
            2003,
            561,
            "8JqvMx47wK0",
            bpm: 140
        ),
        single(
            "daniele-mondello-kamikaze",
            "Daniele Mondello - Kamikaze (Activator Remix)",
            "daniele-mondello",
            2003,
            363,
            "7iicE_G0jcE",
            bpm: 150
        ),
        single(
            "titanic-bros-hypnotized",
            "Titanic Bros - Hypnotized (DJ Vortex & Arpa's Dream Remix)",
            "titanic-bros",
            2003,
            421,
            "Gl32Dslpxlg",
            bpm: 150
        ),
        single(
            "blutonium-boy-make-it-loud",
            "Blutonium Boy - Make It Loud (Blutonium Boy Mix)",
            "blutonium-boy",
            2005,
            405,
            "6tkhdcgmJAU",
            bpm: 148
        ),
        single(
            "piero-zeta-manuel-es-warfare",
            "Piero Zeta & Manuel Es - Warfare (DJ Mantes Rmx)",
            "piero-zeta-manuel-es",
            2003,
            318,
            "kGxbQsEjbHk",
            bpm: 148
        )
    ]
}
