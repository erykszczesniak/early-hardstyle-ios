import Core
import DesignSystem
import SwiftUI

/// The global search cover (DESIGN.md §4.7): a large input on black, recent
/// phrases as ghost chips, and results grouped into Sets / DJs / Events.
struct SearchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: SearchViewModel
    @FocusState private var focused: Bool
    @State private var selectedSet: SetCardModel?
    @State private var selectedDJ: DJCardModel?
    @State private var selectedEvent: Event?

    init(viewModel: SearchViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    input
                    if viewModel.query.trimmingCharacters(in: .whitespaces).isEmpty {
                        recents
                    } else {
                        resultGroups
                    }
                }
                .padding(Spacing.gutter)
            }
            .screenBackground()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.Search.cancel) { dismiss() }
                        .tint(Palette.accentBlueBright)
                }
            }
            .navigationDestination(item: $selectedSet) { card in
                if let detail = viewModel.setDetailViewModel(for: card) {
                    SetDetailView(viewModel: detail)
                }
            }
            .navigationDestination(item: $selectedDJ) { card in
                if let detail = viewModel.djDetailViewModel(for: card) {
                    DJDetailView(viewModel: detail)
                }
            }
            .navigationDestination(item: $selectedEvent) { event in
                eventSets(event)
            }
        }
        .tint(Palette.accentBlueBright)
        .task {
            await viewModel.onAppear()
            focused = true
        }
    }

    private var input: some View {
        TextField(L10n.Search.prompt, text: $viewModel.query)
            .font(.system(size: 28, weight: .semibold, design: .rounded))
            .foregroundStyle(Palette.textPrimary)
            .focused($focused)
            .submitLabel(.search)
            .onSubmit { viewModel.rememberQuery() }
            .autocorrectionDisabled()
    }

    @ViewBuilder
    private var recents: some View {
        if !viewModel.recentPhrases.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.md) {
                SectionHeader(L10n.Search.recent)
                FlowChips(phrases: viewModel.recentPhrases) { phrase in
                    viewModel.useRecent(phrase)
                }
            }
        }
    }

    @ViewBuilder
    private var resultGroups: some View {
        let results = viewModel.results
        if results.isEmpty {
            EmptyState(
                systemImage: "magnifyingglass",
                title: L10n.Search.noResultsTitle,
                message: L10n.Search.noResultsMessage(viewModel.query)
            )
            .padding(.top, Spacing.xxl)
        } else {
            if !results.sets.isEmpty {
                group(L10n.Search.sets) {
                    ForEach(results.sets) { card in
                        SetCardRow(
                            model: card,
                            onOpen: { open(card) },
                            onToggleSave: { Task { await viewModel.toggleSave(card.id) } }
                        )
                    }
                }
            }
            if !results.djs.isEmpty {
                group(L10n.Search.djs) {
                    ForEach(results.djs) { card in
                        DJCard(model: card) {
                            viewModel.rememberQuery()
                            selectedDJ = card
                        }
                    }
                }
            }
            if !results.events.isEmpty {
                group(L10n.Search.events) {
                    ForEach(results.events) { event in
                        eventRow(event)
                    }
                }
            }
        }
    }

    private func open(_ card: SetCardModel) {
        viewModel.rememberQuery()
        selectedSet = card
    }

    private func group(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(title)
            content()
        }
    }

    private func eventRow(_ event: Event) -> some View {
        Button {
            viewModel.rememberQuery()
            selectedEvent = event
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(event.name)
                        .font(Typography.cardTitle)
                        .foregroundStyle(Palette.textPrimary)
                    Text(event.country)
                        .font(Typography.meta)
                        .foregroundStyle(Palette.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(Palette.textTertiary)
            }
            .padding(Spacing.md)
            .cardSurface()
        }
        .buttonStyle(.plain)
    }

    private func eventSets(_ event: Event) -> some View {
        ScrollView {
            LazyVStack(spacing: Spacing.cardGap) {
                ForEach(viewModel.sets(for: event)) { card in
                    SetCardRow(
                        model: card,
                        onOpen: { selectedSet = card },
                        onToggleSave: { Task { await viewModel.toggleSave(card.id) } }
                    )
                }
            }
            .padding(Spacing.gutter)
        }
        .screenBackground()
        .navigationTitle(event.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Wrapping row of ghost chips for recent phrases.
private struct FlowChips: View {
    let phrases: [String]
    let onTap: (String) -> Void

    var body: some View {
        FlowLayout(spacing: Spacing.sm) {
            ForEach(phrases, id: \.self) { phrase in
                Button { onTap(phrase) } label: {
                    Chip(phrase, systemImage: "clock.arrow.circlepath")
                }
                .buttonStyle(.plain)
            }
        }
    }
}

/// A minimal flow layout (wraps children onto new lines).
private struct FlowLayout: Layout {
    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache _: inout ()) -> CGSize {
        arrange(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache _: inout ()) {
        let offsets = arrange(proposal: proposal, subviews: subviews).offsets
        for (subview, offset) in zip(subviews, offsets) {
            subview.place(at: CGPoint(x: bounds.minX + offset.x, y: bounds.minY + offset.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, offsets: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var offsets: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            offsets.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return (CGSize(width: maxWidth == .infinity ? x : maxWidth, height: y + rowHeight), offsets)
    }
}
