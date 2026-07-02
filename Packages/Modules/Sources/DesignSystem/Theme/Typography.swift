import SwiftUI

/// Typography tokens. Mapped onto Dynamic Type text styles so every size scales
/// with the user's preferred content size — Dynamic Type is mandatory.
///
/// Display/numeral tokens use the rounded design for the app's heavy, modern
/// wordmark feel; body/meta use the default UI face.
public enum Typography {
    /// Hero — 34/41 bold (largeTitle).
    public static let hero = Font.system(.largeTitle, design: .rounded).weight(.bold)
    /// Title — 22/28 semibold (title2).
    public static let title = Font.system(.title2, design: .rounded).weight(.semibold)
    /// Section header — 20 semibold (title3).
    public static let section = Font.system(.title3, design: .rounded).weight(.semibold)
    /// Card title — 17 semibold (body).
    public static let cardTitle = Font.system(.body).weight(.semibold)
    /// Body — 17/22.
    public static let body = Font.system(.body)
    /// Meta — 13/18 secondary (footnote).
    public static let meta = Font.system(.footnote)
    /// Badge — 11/13 uppercase (caption2), heavy.
    public static let badge = Font.system(.caption2, design: .rounded).weight(.bold)
}
