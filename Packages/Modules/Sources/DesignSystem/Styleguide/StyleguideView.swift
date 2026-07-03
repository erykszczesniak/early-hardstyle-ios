import SwiftUI

/// A living catalogue of the design system, for the debug scheme. Renders every
/// token and foundational component so regressions are caught by eye. The card
/// and motion components extend this in their PR.
public struct StyleguideView: View {
    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                colors
                typography
                components
                cards
                motion
            }
            .padding(Spacing.gutter)
        }
        .screenBackground()
        .foregroundStyle(Palette.textPrimary)
    }

    private var colors: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader("Colors")
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: Spacing.md) {
                swatch("base", Palette.base)
                swatch("elevated", Palette.elevated)
                swatch("elevated2", Palette.elevated2)
                swatch("accentBlue", Palette.accentBlue)
                swatch("blueBright", Palette.accentBlueBright)
                swatch("blueDeep", Palette.accentBlueDeep)
            }
        }
    }

    private func swatch(_ name: String, _ color: Color) -> some View {
        VStack(spacing: Spacing.xs) {
            RoundedRectangle(cornerRadius: Radius.chip, style: .continuous)
                .fill(color)
                .frame(height: 48)
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.chip, style: .continuous)
                        .strokeBorder(Palette.strokeSubtle, lineWidth: 1)
                )
            Text(name)
                .font(Typography.meta)
                .foregroundStyle(Palette.textSecondary)
        }
    }

    private var typography: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader("Typography")
            Text("Hero").font(Typography.hero)
            Text("Title").font(Typography.title)
            Text("Section").font(Typography.section)
            Text("Card title").font(Typography.cardTitle)
            Text("Body").font(Typography.body)
            Text("Meta").font(Typography.meta).foregroundStyle(Palette.textSecondary)
            Text("BADGE").font(Typography.badge)
        }
    }

    private var components: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            SectionHeader("Components")

            HStack {
                Chip("Early Hardstyle")
                Chip("Reverse")
                Chip("Active", style: .filledBlue)
            }

            HStack {
                YearBadge(2007)
                DurationBadge(seconds: 4125)
            }

            PillButton("Play latest", systemImage: "play.fill", role: .primary, fullWidth: true) {}
            PillButton("Secondary", role: .secondary) {}

            SectionHeader("Related sets", actionTitle: "See all") {}

            EmptyState(
                systemImage: "square.grid.2x2",
                title: "No sets yet",
                message: "Sets will appear here once loaded.",
                actionTitle: "Reload"
            ) {}
                .cardSurface()

            ErrorInline(message: "Something went wrong. Please try again.") {}
        }
    }

    private var sampleSet: SetCardModel {
        SetCardModel(
            id: "s1",
            title: "Showtek at Defqon.1",
            eventName: "Defqon.1",
            year: 2007,
            durationSeconds: 4125,
            genres: ["Early Hardstyle", "Reverse"],
            thumbnailURL: nil,
            isSaved: true
        )
    }

    private var cards: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            SectionHeader("Cards")

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.cardGap), count: 2),
                spacing: Spacing.cardGap
            ) {
                SetCard(model: sampleSet, isPlaying: true, onOpen: {}, onToggleSave: {})
                SetCard(model: sampleSet, onOpen: {}, onToggleSave: {})
            }

            SetCardRow(model: sampleSet, onOpen: {}, onToggleSave: {})

            DJCard(
                model: DJCardModel(id: "showtek", name: "Showtek", country: "Netherlands", setCount: 2, imageURL: nil),
                onOpen: {}
            )
            .frame(maxWidth: 180)

            MiniPlayer(
                model: MiniPlayerModel(
                    title: "Technoboy",
                    subtitle: "Sensation Black 2004",
                    thumbnailURL: nil,
                    isPlaying: true,
                    isSaved: false
                ),
                onPlayPause: {},
                onToggleSave: {},
                onOpen: {}
            )
        }
    }

    private var motion: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            SectionHeader("Motion")

            Text("Progress")
                .font(Typography.meta)
                .foregroundStyle(Palette.textSecondary)
            ProgressBar(value: 0.35, onScrub: { _ in })
            ProgressBar(value: 0, isBuffering: true)

            Text("Hero mesh")
                .font(Typography.meta)
                .foregroundStyle(Palette.textSecondary)
            HeroMesh()
                .frame(height: 140)
                .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))

            Text("Tilt / pulse are shown on the cards above and honour Reduce Motion.")
                .font(Typography.meta)
                .foregroundStyle(Palette.textTertiary)
        }
    }
}

#Preview {
    StyleguideView()
}
