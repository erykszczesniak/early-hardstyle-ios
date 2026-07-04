import DesignSystem
import SwiftUI

/// The Set Detail screen: large artwork over a blurred backdrop, metadata, a
/// full-width PLAY entry point, and a rail of related sets.
struct SetDetailView: View {
    @Environment(PlaybackController.self) private var playback
    @State private var viewModel: SetDetailViewModel
    @State private var selectedRelated: SetCardModel?

    init(viewModel: SetDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                artwork
                header
                PillButton(L10n.SetDetail.play, systemImage: "play.fill", role: .primary, fullWidth: true) {
                    playback.play(viewModel.makeQueue())
                }
                related
            }
            .padding(Spacing.gutter)
        }
        .screenBackground()
        .foregroundStyle(Palette.textPrimary)
        .navigationTitle(viewModel.card.eventName)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $selectedRelated) { card in
            detail(for: card)
        }
        .task { await viewModel.onAppear() }
    }

    private var artwork: some View {
        Artwork(url: viewModel.card.thumbnailURL, cornerRadius: Radius.card)
            .frame(maxWidth: .infinity)
            .frame(height: 240)
            .overlay(alignment: .topTrailing) {
                SaveHeart(isSaved: viewModel.isSaved) {
                    Task { await viewModel.toggleSavePrimary() }
                }
                .padding(Spacing.sm)
            }
            .accessibilityHidden(true)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(viewModel.title)
                .font(Typography.title)
            Text(viewModel.djName)
                .font(Typography.cardTitle)
                .foregroundStyle(Palette.accentBlueBright)
            Text(viewModel.metaLine)
                .font(Typography.meta)
                .foregroundStyle(Palette.textSecondary)
            if !viewModel.genres.isEmpty {
                HStack(spacing: Spacing.xs) {
                    ForEach(viewModel.genres, id: \.self) { Chip($0) }
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var related: some View {
        if !viewModel.related.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.md) {
                SectionHeader(L10n.SetDetail.related)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.cardGap) {
                        ForEach(viewModel.related) { card in
                            SetCard(
                                model: card,
                                onOpen: { selectedRelated = card },
                                onToggleSave: { Task { await viewModel.toggleSave(card.id) } }
                            )
                            .frame(width: 190)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func detail(for card: SetCardModel) -> some View {
        if let detailViewModel = viewModel.detailViewModel(for: card) {
            SetDetailView(viewModel: detailViewModel)
        } else {
            SetPlaceholderView(model: card)
        }
    }
}
