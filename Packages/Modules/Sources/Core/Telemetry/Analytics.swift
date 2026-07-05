import Foundation
import os

/// Abstraction over an analytics sink.
///
/// Features depend on this protocol, never on a concrete SDK, so the backend
/// (Firebase, a first-party pipeline, a test spy, …) is swappable at the
/// composition root. `Sendable` because a single instance is shared across the
/// dependency graph and may be invoked from any isolation domain.
public protocol Analytics: Sendable {
    /// Record a single, already-sanitised event.
    func track(_ event: AnalyticsEvent)
}

public extension Analytics {
    /// Convenience for the most common event.
    func trackScreenView(_ screen: String) {
        track(.screenView(screen))
    }

    /// Typo-proof overload over the screen taxonomy.
    func trackScreenView(_ screen: AnalyticsScreen) {
        track(.screenView(screen))
    }
}

/// Default no-op sink. The safe production default until a real backend is
/// wired in, and handy for tests that don't care about analytics.
public struct NoopAnalytics: Analytics {
    public init() {}
    public func track(_: AnalyticsEvent) {}
}

/// Development sink that logs events via the unified logging system. Never used
/// as a data pipeline — purely a visible default during development.
public struct ConsoleAnalytics: Analytics {
    private let logger: Logger

    public init(subsystem: String = Telemetry.subsystem, category: String = "Analytics") {
        logger = Logger(subsystem: subsystem, category: category)
    }

    public func track(_ event: AnalyticsEvent) {
        if event.parameters.isEmpty {
            logger.debug("event: \(event.name, privacy: .public)")
        } else {
            logger.debug("event: \(event.name, privacy: .public) \(Self.describe(event.parameters), privacy: .public)")
        }
    }

    private static func describe(_ parameters: [String: AnalyticsValue]) -> String {
        parameters
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value.displayValue)" }
            .joined(separator: " ")
    }
}

private extension AnalyticsValue {
    var displayValue: String {
        switch self {
        case let .string(value): value
        case let .int(value): String(value)
        case let .double(value): String(value)
        case let .bool(value): String(value)
        }
    }
}
