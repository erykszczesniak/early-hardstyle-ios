import SwiftUI

/// The app's primary call-to-action. Blue-filled `primary` for the main action
/// on a screen, stroke-only `secondary` for quieter ones.
public struct PillButton: View {
    public enum Role: Sendable {
        case primary
        case secondary
    }

    private let title: String
    private let systemImage: String?
    private let role: Role
    private let fullWidth: Bool
    private let action: () -> Void

    public init(
        _ title: String,
        systemImage: String? = nil,
        role: Role = .primary,
        fullWidth: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.role = role
        self.fullWidth = fullWidth
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
            }
            .frame(maxWidth: fullWidth ? .infinity : nil)
        }
        .buttonStyle(PillButtonStyle(role: role))
    }
}

private struct PillButtonStyle: ButtonStyle {
    let role: PillButton.Role

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.cardTitle)
            .foregroundStyle(foreground)
            .padding(.horizontal, Spacing.xl)
            .frame(minHeight: 52)
            .background(background(pressed: configuration.isPressed), in: shape)
            .overlay(shape.strokeBorder(border, lineWidth: role == .secondary ? 1 : 0))
            .opacity(configuration.isPressed && role == .secondary ? 0.7 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: Radius.button, style: .continuous)
    }

    private var foreground: Color {
        switch role {
        case .primary: Palette.textPrimary
        case .secondary: Palette.textPrimary
        }
    }

    private func background(pressed: Bool) -> Color {
        switch role {
        case .primary: pressed ? Palette.accentBlueDeep : Palette.accentBlue
        case .secondary: .clear
        }
    }

    private var border: Color {
        role == .secondary ? Palette.strokeSubtle : .clear
    }
}

#Preview {
    VStack(spacing: Spacing.lg) {
        PillButton("Play latest", systemImage: "play.fill", role: .primary, fullWidth: true) {}
        PillButton("Browse Library", role: .secondary) {}
    }
    .padding()
    .screenBackground()
}
