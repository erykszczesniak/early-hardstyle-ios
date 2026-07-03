import DesignSystem
import SwiftUI

/// The Library screen: an animated hero over a grid of set cards, with search,
/// pull-to-refresh and designed loading/empty/error states.
public struct LibraryView: View {
    @State private var viewModel: LibraryViewModel
    @State private var selectedSet: SetCardModel?
    @State private var showFilters = false

    private let columns = [
        GridItem(.flexible(), spacing: Spacing.cardGap),
        GridItem(.flexible(), spacing: Spacing.cardGap)
    ]

    public init(viewModel: LibraryViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        NavigationStack {
            content
                .screenBackground()
                .navigationTitle("EARLYHS")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(Palette.base, for: .navigationBar)
                .toolbar { filterToolbarItem }
                .navigationDestination(item: $selectedSet) { card in
                    if let detail = viewModel.setDetailViewModel(for: card) {
                        SetDetailView(viewModel: detail)
                    } else {
                        SetPlaceholderView(model: card)
                    }
                }
        }
        .tint(Palette.accentBlueBright)
        .searchable(text: $viewModel.searchQuery, prompt: "Search sets, DJs, events")
        .sheet(isPresented: $showFilters) {
            LibraryFiltersView(viewModel: viewModel)
                .presentationDetents([.medium, .large])
        }
        .task { await viewModel.onAppear() }
    }

    @ToolbarContentBuilder
    private var filterToolbarItem: some ToolbarContent {
        if viewModel.state == .loaded, !viewModel.filterOptions.isEmpty {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showFilters = true } label: {
                    Image(systemName: viewModel.activeFilterCount > 0
                        ? "line.3.horizontal.decrease.circle.fill"
                        : "line.3.horizontal.decrease.circle")
                }
                .accessibilityLabel(
                    viewModel.activeFilterCount > 0
                        ? "Filters, \(viewModel.activeFilterCount) active"
                        : "Filters"
                )
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            loading
        case let .failed(message, retryable):
            ErrorInline(message: message, retry: retryable ? { Task { await viewModel.retry() } } : nil)
        case .empty:
            EmptyState(
                systemImage: "square.grid.2x2",
                title: "No sets yet",
                message: "The catalogue is empty right now. Pull to refresh."
            )
        case .loaded:
            grid
        }
    }

    private var loading: some View {
        ProgressView()
            .controlSize(.large)
            .tint(Palette.accentBlueBright)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var grid: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                if !viewModel.isRefining {
                    hero
                }

                if viewModel.hasNoResults {
                    EmptyState(
                        systemImage: "magnifyingglass",
                        title: "No results",
                        message: "No sets match your search or filters.",
                        actionTitle: "Clear filters",
                        action: viewModel.activeFilterCount > 0 ? { viewModel.clearFilters() } : nil
                    )
                    .padding(.top, Spacing.xxl)
                } else {
                    LazyVGrid(columns: columns, spacing: Spacing.cardGap) {
                        ForEach(viewModel.visibleSets) { set in
                            SetCard(
                                model: set,
                                onOpen: { selectedSet = set },
                                onToggleSave: { Task { await viewModel.toggleSave(set.id) } }
                            )
                        }
                    }
                    .padding(.horizontal, Spacing.gutter)
                }
            }
            .padding(.bottom, Spacing.xxl)
        }
        .refreshable { await viewModel.refresh() }
    }

    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            HeroMesh()
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("THE GOLDEN ERA")
                    .font(Typography.badge)
                    .tracking(1.2)
                    .foregroundStyle(Palette.textSecondary)
                (Text("Early ").foregroundStyle(Palette.textPrimary)
                    + Text("Hardstyle").foregroundStyle(Palette.accentBlueBright))
                    .font(Typography.hero)
                Text("1999–2007 · raw power")
                    .font(Typography.meta)
                    .foregroundStyle(Palette.textSecondary)
                if let latest = viewModel.latestSet {
                    PillButton("Play latest", systemImage: "play.fill", role: .primary) {
                        selectedSet = latest
                    }
                    .padding(.top, Spacing.xs)
                }
            }
            .padding(Spacing.gutter)
        }
        .frame(height: 300)
        .clipped()
    }
}

/// Interim destination until the Set Detail + Player screens land (features
/// #9/#10). Shows the artwork and title so navigation is real end-to-end.
struct SetPlaceholderView: View {
    let model: SetCardModel

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Artwork(url: model.thumbnailURL)
                .frame(width: 220, height: 220)
            Text(model.title)
                .font(Typography.title)
                .multilineTextAlignment(.center)
            Text(model.metaLine)
                .font(Typography.meta)
                .foregroundStyle(Palette.textSecondary)
            Text("Player coming soon")
                .font(Typography.meta)
                .foregroundStyle(Palette.textTertiary)
        }
        .padding(Spacing.gutter)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .screenBackground()
        .foregroundStyle(Palette.textPrimary)
        .navigationTitle(model.eventName)
        .navigationBarTitleDisplayMode(.inline)
    }
}
