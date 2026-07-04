import Foundation

/// Typed accessors for the component library's fixed user-facing copy (button
/// titles, accessibility labels). Values live in `Resources/Localizable.xcstrings`.
///
/// Composed spoken labels (`DurationBadge.accessibleDuration`,
/// `SetCardModel.accessibilityLabel`, `DJCardModel.subtitle`) intentionally stay
/// code-built pure functions while the app ships English-only — localizing them
/// properly needs per-language plural/format rules, noted for when a second
/// language lands.
enum L10n {
    static let retry = String(localized: "retry", defaultValue: "Retry", bundle: .module)
    static let save = String(localized: "saveHeart.save", defaultValue: "Save", bundle: .module)
    static let saved = String(localized: "saveHeart.saved", defaultValue: "Saved", bundle: .module)
    static let play = String(localized: "miniPlayer.play", defaultValue: "Play", bundle: .module)
    static let pause = String(localized: "miniPlayer.pause", defaultValue: "Pause", bundle: .module)
    static let opensPlayer = String(
        localized: "miniPlayer.opensPlayer", defaultValue: "Opens the player", bundle: .module
    )
    static let playbackPosition = String(
        localized: "progress.label",
        defaultValue: "Playback position",
        bundle: .module
    )

    static func nowPlaying(title: String, subtitle: String) -> String {
        String(localized: "miniPlayer.nowPlaying", defaultValue: "Now playing, \(title), \(subtitle)", bundle: .module)
    }

    static func progressValue(percent: Int) -> String {
        String(localized: "progress.value", defaultValue: "\(percent) percent", bundle: .module)
    }

    static func year(_ year: Int) -> String {
        String(localized: "yearBadge.a11y", defaultValue: "Year \(year)", bundle: .module)
    }
}
