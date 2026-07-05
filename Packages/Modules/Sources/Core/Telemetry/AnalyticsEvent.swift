import Foundation

/// A single, privacy-respecting analytics event.
///
/// Events are value types with a stable `name` and a small, typed parameter
/// bag. Parameters are restricted to `AnalyticsValue` (string/int/double/bool)
/// so that arbitrary objects — and, crucially, PII — cannot leak into an
/// analytics sink by accident. Construct events through the curated `static`
/// factories below rather than free-form strings, so the event taxonomy stays
/// reviewable in one place.
public struct AnalyticsEvent: Equatable, Sendable {
    /// Stable, snake_case event identifier (e.g. `screen_view`).
    public let name: String

    /// Typed, non-PII parameters attached to the event.
    public let parameters: [String: AnalyticsValue]

    public init(name: String, parameters: [String: AnalyticsValue] = [:]) {
        self.name = name
        self.parameters = parameters
    }
}

/// The closed set of value types allowed in an ``AnalyticsEvent`` parameter bag.
///
/// Keeping this an enum (rather than `Any`) is a deliberate privacy guardrail:
/// callers cannot smuggle rich objects, and every value is trivially loggable.
public enum AnalyticsValue: Equatable, Sendable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
}

// MARK: - Curated event factories

/// The app's tracked screens — a closed, typo-proof taxonomy. Raw values are
/// the stable identifiers that reach the analytics sink (never localized).
public enum AnalyticsScreen: String, Sendable {
    case library = "Library"
    case djs = "DJs"
    case djDetail = "DJ Detail"
    case saved = "Saved"
    case setDetail = "Set Detail"
    case player = "Player"
    case tracks = "Tracks"
    case search = "Search"
}

public extension AnalyticsEvent {
    /// A screen/tab became visible. `name` is a stable screen identifier, never
    /// user content.
    static func screenView(_ screen: String) -> AnalyticsEvent {
        AnalyticsEvent(name: "screen_view", parameters: ["screen": .string(screen)])
    }

    /// Typo-proof overload over the screen taxonomy.
    static func screenView(_ screen: AnalyticsScreen) -> AnalyticsEvent {
        screenView(screen.rawValue)
    }
}
