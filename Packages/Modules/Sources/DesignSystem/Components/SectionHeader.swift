import SwiftUI

/// A section title with an optional trailing action (e.g. "Related sets ▸").
public struct SectionHeader: View {
    private let title: String
    private let actionTitle: String?
    private let action: (() -> Void)?

    public init(_ title: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.title = title
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(Typography.section)
                .foregroundStyle(Palette.textPrimary)
            Spacer(minLength: Spacing.sm)
            if let actionTitle, let action {
                Button(action: action) {
                    HStack(spacing: Spacing.xs) {
                        Text(actionTitle)
                        Image(systemName: "chevron.right")
                    }
                    .font(Typography.meta.weight(.semibold))
                    .foregroundStyle(Palette.accentBlueBright)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

#Preview {
    VStack(spacing: Spacing.lg) {
        SectionHeader("Library")
        SectionHeader("Related sets", actionTitle: "See all") {}
    }
    .padding()
    .screenBackground()
}
