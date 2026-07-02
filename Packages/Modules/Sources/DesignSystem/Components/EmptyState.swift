import SwiftUI

/// The designed empty state used by every list screen: a large ghost glyph, a
/// headline, an optional message and an optional primary action.
public struct EmptyState: View {
    private let systemImage: String
    private let title: String
    private let message: String?
    private let actionTitle: String?
    private let action: (() -> Void)?

    public init(
        systemImage: String,
        title: String,
        message: String? = nil,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.systemImage = systemImage
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: systemImage)
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(Palette.accentBlueBright)
                .padding(.bottom, Spacing.xs)

            Text(title)
                .font(Typography.title)
                .foregroundStyle(Palette.textPrimary)
                .multilineTextAlignment(.center)

            if let message {
                Text(message)
                    .font(Typography.body)
                    .foregroundStyle(Palette.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle, let action {
                PillButton(actionTitle, role: .primary, action: action)
                    .padding(.top, Spacing.xs)
            }
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    EmptyState(
        systemImage: "heart",
        title: "Nothing saved yet",
        message: "Tap ♥ on any set to keep it here.",
        actionTitle: "Browse Library"
    ) {}
        .frame(maxHeight: .infinity)
        .screenBackground()
}
