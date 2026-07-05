import Core
import SwiftUI

/// Presentation model for a set card — decoupled from Core so DesignSystem
/// stays independent and previewable. Features map their domain models onto it.
public struct SetCardModel: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let eventName: String
    public let year: Int
    public let durationSeconds: Int
    public let genres: [String]
    public let thumbnailURL: URL?
    public let isSaved: Bool
    /// Dominant tempo, when known — surfaced by the Tracks screen.
    public let bpm: Int?

    public init(
        id: String,
        title: String,
        eventName: String,
        year: Int,
        durationSeconds: Int,
        genres: [String],
        thumbnailURL: URL?,
        isSaved: Bool,
        bpm: Int? = nil
    ) {
        self.id = id
        self.title = title
        self.eventName = eventName
        self.year = year
        self.durationSeconds = durationSeconds
        self.genres = genres
        self.thumbnailURL = thumbnailURL
        self.isSaved = isSaved
        self.bpm = bpm
    }

    /// Secondary meta line, e.g. "Defqon.1 · 2007".
    public var metaLine: String {
        "\(eventName) · \(year)"
    }

    /// Combined VoiceOver label. `nonisolated`/pure so it is testable and
    /// callable from any context.
    public static func accessibilityLabel(for model: SetCardModel) -> String {
        let saved = model.isSaved ? "saved" : "not saved"
        let duration = DurationBadge.accessibleDuration(seconds: model.durationSeconds)
        return "Set, \(model.title), \(model.eventName) \(model.year), \(duration), \(saved)"
    }
}

/// The signature grid set card: artwork with year/duration/save overlays, title,
/// meta and up to two genre chips. Pulses when playing.
public struct SetCard: View {
    private let model: SetCardModel
    private let isPlaying: Bool
    private let onOpen: () -> Void
    private let onToggleSave: () -> Void

    public init(
        model: SetCardModel,
        isPlaying: Bool = false,
        onOpen: @escaping () -> Void,
        onToggleSave: @escaping () -> Void
    ) {
        self.model = model
        self.isPlaying = isPlaying
        self.onOpen = onOpen
        self.onToggleSave = onToggleSave
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            artwork
            // Reserve two title lines so every card in a grid row is the same
            // height regardless of title length.
            Text(model.title)
                .font(Typography.cardTitle)
                .foregroundStyle(Palette.textPrimary)
                .lineLimit(2, reservesSpace: true)
            Text(model.metaLine)
                .font(Typography.meta)
                .foregroundStyle(Palette.textSecondary)
                .lineLimit(1)
            genreChips
        }
        .padding(Spacing.md)
        .cardSurface()
        .pulseGlow(isActive: isPlaying)
        .contentShape(Rectangle())
        .onTapGesture(perform: onOpen)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(SetCardModel.accessibilityLabel(for: model))
        .accessibilityAddTraits(.isButton)
    }

    /// One-line, non-hyphenating chips: two if they fit, otherwise one
    /// (truncating). A hidden template chip reserves the row height even when a
    /// set has no genres, keeping all cards in a grid row equal.
    private var genreChips: some View {
        ZStack(alignment: .leading) {
            Chip("Hardstyle").hidden()
            if !model.genres.isEmpty {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: Spacing.xs) {
                        ForEach(model.genres.prefix(2), id: \.self) { genre in
                            Chip(genre).fixedSize()
                        }
                    }
                    Chip(model.genres[0])
                }
            }
        }
    }

    private var artwork: some View {
        Artwork(url: model.thumbnailURL)
            .frame(height: 112)
            .frame(maxWidth: .infinity)
            .overlay(alignment: .topLeading) { YearBadge(model.year).padding(Spacing.sm) }
            .overlay(alignment: .topTrailing) {
                SaveHeart(isSaved: model.isSaved, action: onToggleSave).padding(Spacing.xs)
            }
            .overlay(alignment: .bottomTrailing) {
                DurationBadge(seconds: model.durationSeconds).padding(Spacing.sm)
            }
            .accessibilityHidden(true)
    }
}

/// The full-width row variant used in DJ detail and search results.
public struct SetCardRow: View {
    private let model: SetCardModel
    private let onOpen: () -> Void
    private let onToggleSave: () -> Void

    public init(
        model: SetCardModel,
        onOpen: @escaping () -> Void,
        onToggleSave: @escaping () -> Void
    ) {
        self.model = model
        self.onOpen = onOpen
        self.onToggleSave = onToggleSave
    }

    public var body: some View {
        HStack(spacing: Spacing.md) {
            Artwork(url: model.thumbnailURL)
                .frame(width: 88, height: 88)
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(model.title)
                    .font(Typography.cardTitle)
                    .foregroundStyle(Palette.textPrimary)
                    .lineLimit(2)
                Text(model.metaLine)
                    .font(Typography.meta)
                    .foregroundStyle(Palette.textSecondary)
                    .lineLimit(1)
                Text(HardstyleSet.formatDuration(seconds: model.durationSeconds))
                    .font(Typography.meta)
                    .foregroundStyle(Palette.textTertiary)
            }
            Spacer(minLength: Spacing.sm)
            SaveHeart(isSaved: model.isSaved, action: onToggleSave)
        }
        .padding(Spacing.md)
        .cardSurface()
        .contentShape(Rectangle())
        .onTapGesture(perform: onOpen)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(SetCardModel.accessibilityLabel(for: model))
        .accessibilityAddTraits(.isButton)
    }
}
