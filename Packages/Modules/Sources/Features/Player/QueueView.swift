import DesignSystem
import SwiftUI

/// The play queue, presented over the player: reorder, remove, jump to a track,
/// and toggle autoplay. The currently-playing row is marked.
struct QueueView: View {
    @Bindable var controller: PlaybackController
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle(L10n.Queue.autoplayNext, isOn: $controller.autoplayNext)
                        .tint(Palette.accentBlue)
                        .listRowBackground(Palette.elevated)
                }

                Section(L10n.Queue.upNext) {
                    ForEach(controller.queue) { item in
                        row(for: item)
                            .listRowBackground(Palette.elevated)
                    }
                    .onDelete(perform: delete)
                    .onMove { controller.move(fromOffsets: $0, toOffset: $1) }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .screenBackground()
            .navigationTitle(L10n.Queue.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { EditButton().tint(Palette.accentBlueBright) }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.Queue.done) { dismiss() }.tint(Palette.accentBlueBright)
                }
            }
        }
    }

    private func row(for item: QueueItem) -> some View {
        let isCurrent = controller.nowPlaying?.setID == item.id
        return Button {
            if let position = controller.queue.firstIndex(where: { $0.id == item.id }) {
                controller.play(at: position)
            }
        } label: {
            HStack(spacing: Spacing.md) {
                Artwork(url: item.nowPlaying.artworkURL, cornerRadius: Radius.chip)
                    .frame(width: 48, height: 48)
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.nowPlaying.title)
                        .font(Typography.cardTitle)
                        .foregroundStyle(isCurrent ? Palette.accentBlueBright : Palette.textPrimary)
                        .lineLimit(1)
                    Text(item.nowPlaying.subtitle)
                        .font(Typography.meta)
                        .foregroundStyle(Palette.textSecondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                if isCurrent {
                    Image(systemName: "waveform")
                        .foregroundStyle(Palette.accentBlueBright)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func delete(at offsets: IndexSet) {
        let items = offsets.map { controller.queue[$0] }
        for item in items {
            controller.remove(item)
        }
    }
}
