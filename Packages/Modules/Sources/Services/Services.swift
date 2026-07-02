import Core
import Foundation

/// Root namespace for the Services module: catalog, favourites and playback
/// services live here as protocols (with live + mock implementations) so that
/// Features depend on abstractions, never concretions.
public enum Services {
    /// Human-readable module identifier, surfaced in the debug styleguide.
    public static let moduleName = "Services"

    /// The Core module this layer is built on top of.
    public static let coreModuleName = Core.moduleName
}
