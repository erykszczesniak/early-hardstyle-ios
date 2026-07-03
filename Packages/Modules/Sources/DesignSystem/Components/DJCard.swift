import SwiftUI

/// Presentation model for a DJ card.
public struct DJCardModel: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let country: String
    public let setCount: Int
    public let imageURL: URL?

    public init(id: String, name: String, country: String, setCount: Int, imageURL: URL?) {
        self.id = id
        self.name = name
        self.country = country
        self.setCount = setCount
        self.imageURL = imageURL
    }

    /// Secondary line, e.g. "Netherlands · 2 sets". Pure and testable.
    public static func subtitle(country: String, setCount: Int) -> String {
        "\(country) · \(setCount) set\(setCount == 1 ? "" : "s")"
    }
}

/// A DJ card: circular avatar (blue ring on press), name and country · set count.
public struct DJCard: View {
    private let model: DJCardModel
    private let onOpen: () -> Void

    public init(model: DJCardModel, onOpen: @escaping () -> Void) {
        self.model = model
        self.onOpen = onOpen
    }

    public var body: some View {
        VStack(spacing: Spacing.sm) {
            avatar
            Text(model.name)
                .font(Typography.cardTitle)
                .foregroundStyle(Palette.textPrimary)
                .lineLimit(1)
            Text(DJCardModel.subtitle(country: model.country, setCount: model.setCount))
                .font(Typography.meta)
                .foregroundStyle(Palette.textSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.md)
        .cardSurface()
        .contentShape(Rectangle())
        .onTapGesture(perform: onOpen)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "DJ, \(model.name), \(DJCardModel.subtitle(country: model.country, setCount: model.setCount))"
        )
        .accessibilityAddTraits(.isButton)
    }

    private var avatar: some View {
        AsyncImage(url: model.imageURL) { image in
            image.resizable().scaledToFill()
        } placeholder: {
            ZStack {
                Palette.elevated2
                Image(systemName: "person.fill")
                    .font(.system(size: 26, weight: .light))
                    .foregroundStyle(Palette.textTertiary)
            }
        }
        .frame(width: 72, height: 72)
        .clipShape(Circle())
        .overlay(Circle().strokeBorder(Palette.strokeSubtle, lineWidth: 1))
        .accessibilityHidden(true)
    }
}
