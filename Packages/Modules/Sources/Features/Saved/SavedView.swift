import DesignSystem
import SwiftUI

/// The Saved screen: the user's favourited sets, with a designed empty state
/// that invites browsing the Library.
public struct SavedView: View {
    @State private var viewModel: SavedViewModel
    @State private var selectedSet: SetCardModel?
    private let onBrowseLibrary: () -> Void

    private let columns = [
        GridItem(.flexible(), spacing: Spacing.cardGap),
        GridItem(.flexible(), spacing: Spacing.cardGap)
    ]

    public init(viewModel: SavedViewModel, onBrowseLibrary: @escaping () -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onBrowseLibrary = onBrowseLibrary
    }

    public var body: some View {
        NavigationStack {
            content
                .screenBackground()
                .navigationTitle("Saved")
                .navigationBarTitleDisplayMode(.large)
                .navigationDestination(item: $selectedSet) { card in
                    if let detail = viewModel.setDetailViewModel(for: card) {
                        SetDetailView(viewModel: detail)
                    } else {
                        SetPlaceholderView(model: card)
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
            emptyState
        case .loaded:
            grid
        }
    }

    private var emptyState: some View {
        EmptyState(
            systemImage: "heart",
            title: "Nothing saved yet",
            message: "Tap ♥ on any set to keep it here.",
            actionTitle: "Browse Library",
            action: onBrowseLibrary
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var grid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: Spacing.cardGap) {
                ForEach(viewModel.sets) { set in
                    SetCard(
                        model: set,
                        onOpen: { selectedSet = set },
                        onToggleSave: { Task { await viewModel.toggleSave(set.id) } }
                    )
                }
            }
            .padding(Spacing.gutter)
        }
    }
}
