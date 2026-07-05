import AppIntents
import Features
import Foundation

/// "Play the latest set" — exposed to Siri, Spotlight and the Shortcuts app.
/// The intent opens the app via the deep link, so playback flows through the
/// exact same path as a widget tap or a URL (single code path, no side doors).
/// iOS 18+ because `OpenURLIntent` is; on iOS 17 the app simply exposes no
/// shortcut (the deep link itself works everywhere).
@available(iOS 18.0, *)
struct PlayLatestSetIntent: AppIntent {
    static let title: LocalizedStringResource = "Play the Latest Set"
    static let description = IntentDescription("Starts playing the newest early-hardstyle set in the catalogue.")
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult & OpensIntent {
        guard let url = DeepLink.playLatest.url else {
            throw AppIntentError.restartPerform
        }
        return .result(opensIntent: OpenURLIntent(url))
    }
}

@available(iOS 18.0, *)
struct EarlyHSShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: PlayLatestSetIntent(),
            phrases: ["Play the latest set in \(.applicationName)"],
            shortTitle: "Play Latest",
            systemImageName: "play.fill"
        )
    }
}
