import Foundation
import os

/// Abstraction over a crash-reporting / non-fatal-error sink.
///
/// Mirrors the shape of common SDKs (Crashlytics, Sentry) without binding to
/// one: breadcrumb logs, non-fatal error recording and non-PII context keys.
/// Injected at the composition root so tests can assert on what was reported.
public protocol CrashReporter: Sendable {
    /// Leave a breadcrumb describing app state ahead of a potential crash.
    func log(_ message: String)

    /// Record a non-fatal error with optional, non-PII context.
    func record(_ error: Error, context: [String: String])

    /// Attach a non-PII key/value that will accompany future crash reports.
    /// Pass `nil` to clear the key.
    func setContextValue(_ value: String?, forKey key: String)
}

public extension CrashReporter {
    /// Record a non-fatal error without extra context.
    func record(_ error: Error) {
        record(error, context: [:])
    }
}

/// Default no-op reporter — the safe production default until a real backend is
/// wired in.
public struct NoopCrashReporter: CrashReporter {
    public init() {}
    public func log(_: String) {}
    public func record(_: Error, context _: [String: String]) {}
    public func setContextValue(_: String?, forKey _: String) {}
}

/// Development reporter that writes to the unified logging system so crashes and
/// non-fatals are visible in the console during development.
public struct ConsoleCrashReporter: CrashReporter {
    private let logger: Logger

    public init(subsystem: String = Telemetry.subsystem, category: String = "Crash") {
        logger = Logger(subsystem: subsystem, category: category)
    }

    public func log(_ message: String) {
        logger.log("breadcrumb: \(message, privacy: .public)")
    }

    public func record(_ error: Error, context: [String: String]) {
        if context.isEmpty {
            logger.error("non-fatal: \(String(describing: error), privacy: .public)")
        } else {
            let describedContext = context
                .sorted { $0.key < $1.key }
                .map { "\($0.key)=\($0.value)" }
                .joined(separator: " ")
            logger.error(
                "non-fatal: \(String(describing: error), privacy: .public) [\(describedContext, privacy: .public)]"
            )
        }
    }

    public func setContextValue(_ value: String?, forKey key: String) {
        logger.debug("context: \(key, privacy: .public)=\(value ?? "nil", privacy: .public)")
    }
}
