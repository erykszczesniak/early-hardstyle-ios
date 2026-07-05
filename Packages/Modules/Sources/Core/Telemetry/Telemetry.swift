/// Bundles the telemetry sinks so a single value can be injected through the
/// dependency graph. Features receive `Telemetry` (or, more narrowly, one of
/// its protocols) via initialiser injection — never a global.
public struct Telemetry: Sendable {
    /// The app's unified-logging subsystem, shared by the console sinks.
    public static let subsystem = "com.erykszczesniak.EarlyHardstyle"

    public let analytics: any Analytics
    public let crashReporter: any CrashReporter

    public init(analytics: any Analytics, crashReporter: any CrashReporter) {
        self.analytics = analytics
        self.crashReporter = crashReporter
    }

    /// Fully inert telemetry — the default for tests and previews.
    public static var noop: Telemetry {
        Telemetry(analytics: NoopAnalytics(), crashReporter: NoopCrashReporter())
    }

    /// Console-logging telemetry — the visible default during development.
    public static var console: Telemetry {
        Telemetry(analytics: ConsoleAnalytics(), crashReporter: ConsoleCrashReporter())
    }
}
