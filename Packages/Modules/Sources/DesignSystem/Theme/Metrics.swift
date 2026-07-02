import CoreGraphics

/// Spacing tokens on a 4pt grid (see `the design spec`).
public enum Spacing {
    public static let xs: CGFloat = 4
    public static let sm: CGFloat = 8
    public static let md: CGFloat = 12
    public static let cardGap: CGFloat = 14
    public static let lg: CGFloat = 16
    public static let gutter: CGFloat = 20
    public static let xl: CGFloat = 24
    public static let xxl: CGFloat = 32
}

/// Corner-radius tokens.
public enum Radius {
    public static let card: CGFloat = 20
    public static let thumbnail: CGFloat = 16
    public static let button: CGFloat = 14
    public static let chip: CGFloat = 10
    public static let miniPlayer: CGFloat = 24
}
