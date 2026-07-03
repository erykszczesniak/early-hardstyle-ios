import DesignSystem
import SwiftUI

/// A DJ's detail: a large avatar header and the DJ's sets as full-width rows.
struct DJDetailView: View {
    @State private var viewModel: DJDetailViewModel
    @State private var selectedSet: SetCardModel?

    init(viewModel: DJDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                header
                LazyVStack(spacing: Spacing.cardGap) {
                    ForEach(viewModel.sets) { set in
                        SetCardRow(
                            model: set,
                            onOpen: { selectedSet = set },
                            onToggleSave: { Task { await viewModel.toggleSave(set.id) } }
                        )
                    }
                }
            }
            .padding(Spacing.gutter)
        }
        .screenBackground()
        .foregroundStyle(Palette.textPrimary)
        .navigationTitle(viewModel.dj.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $selectedSet) { set in
            SetPlaceholderView(model: set)
        }
        .task { await viewModel.onAppear() }
    }

    private var header: some View {
        HStack(spacing: Spacing.lg) {
            avatar
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(viewModel.dj.name)
                    .font(Typography.hero)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                Text(viewModel.subtitle)
                    .font(Typography.meta)
                    .foregroundStyle(Palette.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }

    private var avatar: some View {
        AsyncImage(url: viewModel.dj.imageURL) { image in
            image.resizable().scaledToFill()
        } placeholder: {
            ZStack {
                Palette.elevated2
                Image(systemName: "person.fill")
                    .font(.system(size: 30, weight: .light))
                    .foregroundStyle(Palette.textTertiary)
            }
        }
        .frame(width: 96, height: 96)
        .clipShape(Circle())
        .overlay(Circle().strokeBorder(Palette.strokeSubtle, lineWidth: 1))
        .accessibilityHidden(true)
    }
}
