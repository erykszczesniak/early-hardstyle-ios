import SwiftUI

/// The compact error card used by every network surface: a message and, when
/// the failure is retryable, a blue Retry action.
public struct ErrorInline: View {
    private let message: String
    private let retryTitle: String
    private let retry: (() -> Void)?

    /// `retryTitle` defaults to the localized "Retry" (resolved internally —
    /// an internal symbol can't appear in a public default argument).
    public init(message: String, retryTitle: String? = nil, retry: (() -> Void)? = nil) {
        self.message = message
        self.retryTitle = retryTitle ?? L10n.retry
        self.retry = retry
    }

    public var body: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 28, weight: .regular))
                .foregroundStyle(Palette.textSecondary)

            Text(message)
                .font(Typography.body)
                .foregroundStyle(Palette.textPrimary)
                .multilineTextAlignment(.center)

            if let retry {
                Button(action: retry) {
                    Text(retryTitle)
                        .font(Typography.cardTitle)
                        .foregroundStyle(Palette.accentBlueBright)
                }
                .padding(.top, Spacing.xs)
            }
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity)
        .cardSurface()
        .padding(Spacing.gutter)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    ErrorInline(message: "You're offline. Check your connection and try again.") {}
        .frame(maxHeight: .infinity)
        .screenBackground()
}
