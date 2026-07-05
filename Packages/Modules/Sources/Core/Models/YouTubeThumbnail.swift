import Foundation

/// The single source of the YouTube thumbnail URL template — set artwork and
/// DJ avatars both derive from official video thumbnails (never copied or
/// self-hosted artwork).
public enum YouTubeThumbnail {
    public enum Quality: String, Sendable {
        /// 320×180, natively 16:9 (no letterbox bars) — right for circular crops.
        case medium = "mqdefault"
        /// 480×360, 4:3 with letterboxing — right for wide artwork slots.
        case high = "hqdefault"
    }

    public static func url(videoID: String, quality: Quality = .high) -> URL? {
        URL(string: "https://i.ytimg.com/vi/\(videoID)/\(quality.rawValue).jpg")
    }
}
