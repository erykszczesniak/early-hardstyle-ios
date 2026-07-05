import Foundation

/// The app's deep-link vocabulary (`earlyhs://…`). Parsed by the root view's
/// `onOpenURL`; produced by widgets and App Intents.
public enum DeepLink: Equatable, Sendable {
    /// The custom URL scheme (declared in the app's Info.plist).
    public static let scheme = "earlyhs"

    /// Play a specific set (with its related queue).
    case play(setID: String)
    /// Play the newest set in the catalogue.
    case playLatest

    /// Parses a deep link, or nil for foreign/malformed URLs.
    public static func parse(_ url: URL) -> DeepLink? {
        guard url.scheme == scheme, url.host == "play" else { return nil }
        let id = url.pathComponents.count > 1 ? url.pathComponents[1] : ""
        guard !id.isEmpty else { return nil }
        return id == "latest" ? .playLatest : .play(setID: id)
    }

    /// The URL form of this link.
    public var url: URL? {
        switch self {
        case let .play(setID):
            URL(string: "\(Self.scheme)://play/\(setID)")
        case .playLatest:
            URL(string: "\(Self.scheme)://play/latest")
        }
    }
}
