import DesignSystem
import SwiftUI

/// The Tracks screen: every track with its tempo, re-sortable by BPM (hardest
/// first), year or title.
public struct TracksView: View {
    @State private var viewModel: TracksViewModel
    @State private var selectedTrack: SetCardModel?

    public init(viewModel: TracksViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        NavigationStack {
            content
                .screenBackground()
                .navigationTitle(L10n.Tracks.title)
                .navigationBarTitleDisplayMode(.large)
                .navigationDestination(item: $selectedTrack) { card in
                    if let detail = viewModel.setDetailViewModel(for: card) {
                        SetDetailView(viewModel: detail)
                    }
                }
        }
        .tint(Palette.accentBlueBright)
        .task { await viewModel.onAppear() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView()
                .controlSize(.large)
                .tint(Palette.accentBlueBright)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case let .failed(message, retryable):
            ErrorInline(message: message, retry: retryable ? { Task { await viewModel.retry() } } : nil)
        case .empty:
            EmptyState(
                systemImage: "metronome",
                title: L10n.Tracks.emptyTitle,
                message: L10n.Common.catalogueEmptyMessage
            )
        case .loaded:
            list
        }
    }

    private var list: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                sortPicker
                GlassGroup(spacing: Spacing.cardGap) {
                    LazyVStack(spacing: Spacing.cardGap) {
                        ForEach(viewModel.tracks) { track in
                            TrackRow(model: track) { selectedTrack = track }
                        }
                    }
                }
            }
            .padding(Spacing.gutter)
        }
    }

    private var sortPicker: some View {
        Picker(L10n.Tracks.sortLabel, selection: $viewModel.sort) {
            Text(L10n.Tracks.sortBPM).tag(TrackSort.bpm)
            Text(L10n.Tracks.sortNewest).tag(TrackSort.newest)
            Text(L10n.Tracks.sortAlphabetical).tag(TrackSort.alphabetical)
        }
        .pickerStyle(.segmented)
    }
}
