import DesignSystem
import SwiftUI

/// The DJs screen: a grid of DJ cards with search, pushing to a DJ detail.
public struct DJsView: View {
    @State private var viewModel: DJsViewModel
    @State private var selectedDJ: DJCardModel?

    private let columns = [
        GridItem(.flexible(), spacing: Spacing.cardGap),
        GridItem(.flexible(), spacing: Spacing.cardGap)
    ]

    public init(viewModel: DJsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        NavigationStack {
            content
                .screenBackground()
                .navigationTitle(L10n.DJs.title)
                .navigationBarTitleDisplayMode(.large)
                .navigationDestination(item: $selectedDJ) { card in
                    detail(for: card)
                }
        }
        .tint(Palette.accentBlueBright)
        .searchable(text: $viewModel.searchQuery, prompt: Text(L10n.DJs.searchPrompt))
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
                systemImage: "person.2",
                title: L10n.DJs.emptyTitle,
                message: L10n.Common.catalogueEmptyMessage
            )
        case .loaded:
            grid
        }
    }

    private var grid: some View {
        ScrollView {
            if viewModel.hasNoResults {
                EmptyState(
                    systemImage: "magnifyingglass",
                    title: L10n.DJs.noResultsTitle,
                    message: L10n.DJs.noResultsMessage(viewModel.searchQuery)
                )
                .padding(.top, Spacing.xxl)
            } else {
                LazyVGrid(columns: columns, spacing: Spacing.cardGap) {
                    ForEach(viewModel.visibleDJs) { card in
                        DJCard(model: card) { selectedDJ = card }
                    }
                }
                .padding(Spacing.gutter)
            }
        }
        .refreshable { await viewModel.refresh() }
    }

    @ViewBuilder
    private func detail(for card: DJCardModel) -> some View {
        if let detailViewModel = viewModel.detailViewModel(for: card) {
            DJDetailView(viewModel: detailViewModel)
        } else {
            EmptyState(systemImage: "person.crop.circle.badge.exclamationmark", title: L10n.DJs.unavailable)
                .screenBackground()
        }
    }
}
