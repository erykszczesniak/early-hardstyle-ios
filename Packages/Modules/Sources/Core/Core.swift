import Foundation

/// Root namespace for the Core module: shared models, telemetry protocols and
/// primitives that every other module is allowed to depend on.
///
/// Concrete models (`Dj`, `HardstyleSet`, `Event`, …), the telemetry
/// abstractions and typed errors land here in later feature PRs. For the
/// scaffold this only carries module metadata so the boundary is real and
/// testable.
public enum Core {
    /// Human-readable module identifier, surfaced in the debug styleguide.
    public static let moduleName = "Core"
}
