import Core
import Foundation

/// The seeded catalogue: real early-hardstyle DJs, events and iconic
/// tracks/sets, each pointing at an **official YouTube upload** (no ripped or
/// self-hosted media). A tribute — not affiliated with any labels or events.
///
/// YouTube ids were sourced from official/label channel uploads; swap any id
/// here to update a set's video.
public enum SeedCatalog {
    public static let catalog = Catalog(
        djs: djs,
        events: events,
        genres: genres,
        sets: sets
    )

    /// Official YouTube thumbnail for one of the DJ's own seeded uploads —
    /// avatars follow the same "official thumbnails only" rule as set artwork.
    private static func avatar(_ youtubeID: String) -> URL? {
        // mqdefault is natively 16:9 (no letterbox bars), so it fills the
        // circular avatar crop cleanly.
        URL(string: "https://i.ytimg.com/vi/\(youtubeID)/mqdefault.jpg")
    }

    private static let djs: [Dj] = [
        Dj(
            id: "headhunterz",
            name: "Headhunterz",
            country: "Netherlands",
            imageURL: avatar("GMZ2fqCFe2Q"),
            bio: "Willem Rebergen — a defining voice of late-golden-era hardstyle."
        ),
        Dj(
            id: "showtek",
            name: "Showtek",
            country: "Netherlands",
            imageURL: avatar("W_wQYwb0SVM"),
            bio: "The Janssen brothers from Eindhoven; architects of the raw early sound."
        ),
        Dj(
            id: "technoboy",
            name: "Technoboy",
            country: "Italy",
            imageURL: avatar("f3UGKYFv4dE"),
            bio: "Italy's hardstyle pioneer, known for anthemic energy."
        ),
        Dj(
            id: "the-prophet",
            name: "The Prophet",
            country: "Netherlands",
            imageURL: avatar("wZEtCpIzU3E"),
            bio: "Dov Elkabas — Scantraxx founder and a forefather of the genre."
        ),
        Dj(
            id: "brennan-heart",
            name: "Brennan Heart",
            country: "Netherlands",
            imageURL: avatar("Q0r0pu8A6Z0"),
            bio: "Fabian Bohn — melodic hardstyle craftsman."
        ),
        Dj(
            id: "wildstylez",
            name: "Wildstylez",
            country: "Netherlands",
            imageURL: avatar("WA0t6ErCtus"),
            bio: "Joram Metekohy — a leading nu-style voice from 2007 onward."
        ),
        Dj(
            id: "a-lusion",
            name: "A-lusion",
            country: "Netherlands",
            imageURL: avatar("NihtG2OeZPs"),
            bio: "Manuel Berk — a long-standing Dutch hardstyle producer."
        )
    ]

    private static let events: [Event] = [
        Event(id: "defqon-1", name: "Defqon.1", country: "Netherlands"),
        Event(id: "qlimax", name: "Qlimax", country: "Netherlands"),
        Event(id: "in-qontrol", name: "In Qontrol", country: "Netherlands"),
        Event(id: "sensation-black", name: "Sensation Black", country: "Netherlands"),
        Event(id: "mysteryland", name: "Mysteryland", country: "Netherlands"),
        Event(id: "q-base", name: "Q-BASE", country: "Germany"),
        Event(id: "decibel", name: "Decibel Outdoor", country: "Netherlands")
    ]

    private static let genres: [Genre] = [
        Genre(id: "early-hardstyle", name: "Early Hardstyle"),
        Genre(id: "reverse-bass", name: "Reverse Bass"),
        Genre(id: "nu-style", name: "Nu-Style Hardstyle"),
        Genre(id: "raw", name: "Raw Hardstyle")
    ]

    // swiftlint:disable function_parameter_count
    private static func set(
        _ id: String,
        _ title: String,
        _ dj: String,
        _ event: String,
        _ year: Int,
        _ seconds: Int,
        _ youtube: String,
        _ genres: [String]
    ) -> HardstyleSet {
        HardstyleSet(
            id: id,
            title: title,
            djID: dj,
            eventID: event,
            year: year,
            durationSeconds: seconds,
            youtubeID: youtube,
            genreIDs: genres
        )
    }

    // swiftlint:enable function_parameter_count

    private static let sets: [HardstyleSet] = [
        set(
            "hh-home",
            "Headhunterz — The Home of Hardstyle",
            "headhunterz",
            "defqon-1",
            2007,
            3720,
            "GMZ2fqCFe2Q",
            ["early-hardstyle"]
        ),
        set(
            "hh-hws",
            "Headhunterz — HARD with STYLE",
            "headhunterz",
            "in-qontrol",
            2007,
            3600,
            "d5YuAzUbqe8",
            ["nu-style"]
        ),
        set("hh-destiny", "Headhunterz — Destiny", "headhunterz", "qlimax", 2007, 3480, "e6NaYcpmREQ", ["nu-style"]),
        set(
            "hh-down",
            "Headhunterz & Wildstylez — Down With The Bassdrum",
            "headhunterz",
            "defqon-1",
            2007,
            3300,
            "eb8D5u0vp2o",
            ["nu-style"]
        ),
        set(
            "stk-early",
            "Showtek — Best of Early Hardstyle",
            "showtek",
            "sensation-black",
            2004,
            3900,
            "poSBsazzVSw",
            ["early-hardstyle"]
        ),
        set(
            "stk-old",
            "Showtek — Old Hardstyle Times",
            "showtek",
            "mysteryland",
            2003,
            3600,
            "W_wQYwb0SVM",
            ["early-hardstyle", "reverse-bass"]
        ),
        set("stk-dear", "Showtek — Dear Hardstyle", "showtek", "defqon-1", 2007, 3200, "ELI83k5WBwM", ["nu-style"]),
        set(
            "stk-hardcore",
            "Showtek — Do You Like It Hardcore",
            "showtek",
            "q-base",
            2005,
            3000,
            "DtSdAgByKIM",
            ["raw", "early-hardstyle"]
        ),
        set("tb-rage", "Technoboy — Rage", "technoboy", "qlimax", 2007, 3300, "f3UGKYFv4dE", ["nu-style"]),
        set(
            "tb-rage-live",
            "Technoboy — Rage (Live Edit)",
            "technoboy",
            "decibel",
            2006,
            3300,
            "z66TQo8ThOI",
            ["nu-style"]
        ),
        set(
            "tp-classics",
            "The Prophet — Welcome To The Classics",
            "the-prophet",
            "in-qontrol",
            2005,
            3600,
            "FgRunZqWjf0",
            ["early-hardstyle"]
        ),
        set(
            "tp-back",
            "The Prophet — Back In Time",
            "the-prophet",
            "qlimax",
            2004,
            3400,
            "jHedfB7n6wQ",
            ["early-hardstyle", "reverse-bass"]
        ),
        set(
            "tp-listen",
            "The Prophet — Listen To Your Heart",
            "the-prophet",
            "sensation-black",
            2006,
            3200,
            "wZEtCpIzU3E",
            ["nu-style"]
        ),
        set(
            "tp-creatures",
            "The Prophet — Creatures Of The Night",
            "the-prophet",
            "q-base",
            2005,
            3100,
            "nzlwjwI0tVY",
            ["raw"]
        ),
        set(
            "bh-lose",
            "Brennan Heart & Wildstylez — Lose My Mind",
            "brennan-heart",
            "defqon-1",
            2007,
            3000,
            "Q0r0pu8A6Z0",
            ["nu-style"]
        ),
        set(
            "wsz-summer",
            "Wildstylez — Year Of Summer",
            "wildstylez",
            "mysteryland",
            2007,
            3200,
            "WA0t6ErCtus",
            ["nu-style"]
        ),
        set("alu-voodoo", "A-lusion — Voodoo", "a-lusion", "decibel", 2006, 3400, "NihtG2OeZPs", ["early-hardstyle"])
    ]
}

/// The production `CatalogService`: serves the bundled seed catalogue. Swap for a
/// networked implementation without touching any feature code.
public struct BundledCatalogService: CatalogService {
    public init() {}

    public func loadCatalog() async throws -> Catalog {
        SeedCatalog.catalog
    }
}
