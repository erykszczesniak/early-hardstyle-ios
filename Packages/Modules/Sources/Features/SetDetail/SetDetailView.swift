import Core
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
                tracklist
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

    /// The set's tracklist. Rows with a timestamp start playback right at that
    /// track; rows without one (tracklists published without timings) start the
    /// set from the top.
    @ViewBuilder
    private var tracklist: some View {
        if !viewModel.tracklist.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.md) {
                SectionHeader(L10n.SetDetail.tracklist)
                VStack(spacing: 0) {
                    ForEach(viewModel.tracklist) { track in
                        tracklistRow(track)
                        if track.id != viewModel.tracklist.last?.id {
                            Divider().overlay(Palette.strokeSubtle)
                        }
                    }
                }
                .cardSurface()
            }
        }
    }

    private func tracklistRow(_ track: SetTrack) -> some View {
        Button {
            playback.play(viewModel.makeQueue(), fromSeconds: track.startSeconds)
        } label: {
            HStack(spacing: Spacing.md) {
                Text(String(format: "%02d", track.number))
                    .font(Typography.meta)
                    .monospacedDigit()
                    .foregroundStyle(Palette.textTertiary)
                Text(track.title)
                    .font(Typography.body)
                    .foregroundStyle(Palette.textPrimary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if let start = track.formattedStart {
                    Text(start)
                        .font(Typography.meta)
                        .monospacedDigit()
                        .foregroundStyle(Palette.accentBlueBright)
                }
            }
            .padding(Spacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tracklistAccessibilityLabel(for: track))
    }

    private func tracklistAccessibilityLabel(for track: SetTrack) -> String {
        var label = "\(track.number). \(track.title)"
        if let start = track.formattedStart {
            label += ", \(start)"
        }
        return label
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
