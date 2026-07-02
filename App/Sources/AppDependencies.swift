import Core
import Foundation
import Services

/// Composition root for the app.
///
/// This is the single place where concrete implementations are constructed and
/// wired together. Everything downstream (ViewModels, Features) receives its
/// collaborators through initialiser injection from here — there are no hidden
/// singletons in testable code.
///
/// As feature PRs land, their services (telemetry, catalog, favourites, player)
/// are instantiated here and passed into `AppRootView`.
@MainActor
struct AppDependencies {
    /// Analytics + crash reporting, injected downstream to ViewModels.
    let telemetry: Telemetry

    /// Builds the production dependency graph used by the live app. Telemetry
    /// logs to the console in debug builds and stays inert in release until a
    /// real backend is wired in.
    static func live() -> AppDependencies {
        #if DEBUG
            let telemetry = Telemetry.console
        #else
            let telemetry = Telemetry.noop
        #endif
        return AppDependencies(telemetry: telemetry)
    }
}
