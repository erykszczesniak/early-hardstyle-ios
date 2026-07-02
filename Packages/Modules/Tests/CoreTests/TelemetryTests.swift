import Foundation
import XCTest
@testable import Core

// MARK: - Test doubles

/// Thread-safe analytics spy. `Analytics` is `Sendable`, so the spy guards its
/// captured state with a lock rather than relying on actor isolation.
private final class SpyAnalytics: Analytics, @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [AnalyticsEvent] = []

    var events: [AnalyticsEvent] {
        lock.withLock { storage }
    }

    func track(_ event: AnalyticsEvent) {
        lock.withLock { storage.append(event) }
    }
}

private final class SpyCrashReporter: CrashReporter, @unchecked Sendable {
    private let lock = NSLock()
    private(set) var breadcrumbs: [String] = []
    private(set) var recorded: [(error: Error, context: [String: String])] = []
    private(set) var context: [String: String?] = [:]

    func log(_ message: String) {
        lock.withLock { breadcrumbs.append(message) }
    }

    func record(_ error: Error, context: [String: String]) {
        lock.withLock { recorded.append((error, context)) }
    }

    func setContextValue(_ value: String?, forKey key: String) {
        lock.withLock { context[key] = value }
    }
}

private enum SampleError: Error { case boom }

// MARK: - Tests

final class TelemetryTests: XCTestCase {
    func test_track_capturesEvent() {
        let spy = SpyAnalytics()

        spy.track(AnalyticsEvent(name: "custom", parameters: ["n": .int(1)]))

        XCTAssertEqual(spy.events.count, 1)
        XCTAssertEqual(spy.events.first?.name, "custom")
        XCTAssertEqual(spy.events.first?.parameters["n"], .int(1))
    }

    func test_trackScreenView_convenienceProducesScreenViewEvent() {
        let spy = SpyAnalytics()

        spy.trackScreenView("Library")

        XCTAssertEqual(spy.events, [.screenView("Library")])
        XCTAssertEqual(spy.events.first?.parameters["screen"], .string("Library"))
    }

    func test_noopAnalytics_isInert() {
        let sut = NoopAnalytics()
        // Should simply not crash and record nothing observable.
        sut.track(.screenView("DJs"))
        sut.trackScreenView("Saved")
    }

    func test_crashReporter_recordDefaultUsesEmptyContext() {
        let spy = SpyCrashReporter()

        spy.record(SampleError.boom)

        XCTAssertEqual(spy.recorded.count, 1)
        XCTAssertTrue(spy.recorded.first?.context.isEmpty == true)
    }

    func test_crashReporter_capturesBreadcrumbsAndContext() {
        let spy = SpyCrashReporter()

        spy.log("opened player")
        spy.setContextValue("2007", forKey: "year")
        spy.record(SampleError.boom, context: ["stage": "decode"])

        XCTAssertEqual(spy.breadcrumbs, ["opened player"])
        XCTAssertEqual(spy.context["year"], "2007")
        XCTAssertEqual(spy.recorded.first?.context["stage"], "decode")
    }

    func test_noopCrashReporter_isInert() {
        let sut = NoopCrashReporter()
        sut.log("x")
        sut.record(SampleError.boom)
        sut.setContextValue("v", forKey: "k")
    }

    func test_telemetryFactories_provideBothSinks() {
        XCTAssertTrue(Telemetry.noop.analytics is NoopAnalytics)
        XCTAssertTrue(Telemetry.noop.crashReporter is NoopCrashReporter)
        XCTAssertTrue(Telemetry.console.analytics is ConsoleAnalytics)
        XCTAssertTrue(Telemetry.console.crashReporter is ConsoleCrashReporter)
    }
}
