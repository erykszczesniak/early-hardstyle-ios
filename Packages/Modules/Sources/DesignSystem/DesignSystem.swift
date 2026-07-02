import Core
import SwiftUI

/// Root namespace for the DesignSystem module: colour/type/shape tokens, the
/// reusable component inventory (cards, badges, chips, buttons, mini-player)
/// and the 3D/motion modifiers described in `the design spec`.
///
/// Rule of the module: no hex literals or one-off styling may live outside
/// here — every surface pulls from these tokens.
public enum DesignSystem {
    /// Human-readable module identifier, surfaced in the debug styleguide.
    public static let moduleName = "DesignSystem"
}
