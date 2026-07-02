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
    // Telemetry, catalog, favourites and player services are added here in
    // their respective feature PRs and injected downstream.

    /// Builds the production dependency graph used by the live app.
    static func live() -> AppDependencies {
        AppDependencies()
    }
}
