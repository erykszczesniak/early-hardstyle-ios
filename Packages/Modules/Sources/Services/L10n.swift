import Foundation

/// Typed accessors for the service layer's user-facing error copy. Values live
/// in `Resources/Localizable.xcstrings`.
enum L10n {
    static let errorOffline = String(
        localized: "error.offline",
        defaultValue: "You're offline. Check your connection and try again.",
        bundle: .module
    )
    static let errorTimedOut = String(
        localized: "error.timedOut", defaultValue: "The request timed out. Please try again.", bundle: .module
    )
    static let errorUnknown = String(
        localized: "error.unknown", defaultValue: "Something went wrong. Please try again.", bundle: .module
    )

    static func errorDecoding(_ detail: String) -> String {
        String(
            localized: "error.decoding",
            defaultValue: "We couldn't read the catalogue (\(detail)).",
            bundle: .module
        )
    }

    static func errorServer(statusCode: Int) -> String {
        String(
            localized: "error.server",
            defaultValue: "The server returned an error (\(statusCode)). Please try again.",
            bundle: .module
        )
    }
}
