import DesignSystem
import SwiftUI

/// The filter sheet: multi-select facets for year, event, genre and country,
/// bound directly to the Library ViewModel's filter.
struct LibraryFiltersView: View {
    @Bindable var viewModel: LibraryViewModel
    @Environment(\.dismiss) private var dismiss

    private let columns = [GridItem(.adaptive(minimum: 84), spacing: Spacing.sm)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    if !viewModel.filterOptions.years.isEmpty {
                        facet("Year", values: viewModel.filterOptions.years.map { ($0, String($0)) }) {
                            toggle(&viewModel.filter.years, $0)
                        } isSelected: {
                            viewModel.filter.years.contains($0)
                        }
                    }
                    if !viewModel.filterOptions.events.isEmpty {
                        facet("Event", values: viewModel.filterOptions.events.map { ($0.id, $0.name) }) {
                            toggle(&viewModel.filter.eventIDs, $0)
                        } isSelected: {
                            viewModel.filter.eventIDs.contains($0)
                        }
                    }
                    if !viewModel.filterOptions.genres.isEmpty {
                        facet("Genre", values: viewModel.filterOptions.genres.map { ($0.id, $0.name) }) {
                            toggle(&viewModel.filter.genreIDs, $0)
                        } isSelected: {
                            viewModel.filter.genreIDs.contains($0)
                        }
                    }
                    if !viewModel.filterOptions.countries.isEmpty {
                        facet("Country", values: viewModel.filterOptions.countries.map { ($0, $0) }) {
                            toggle(&viewModel.filter.countries, $0)
                        } isSelected: {
                            viewModel.filter.countries.contains($0)
                        }
                    }
                }
                .padding(Spacing.gutter)
            }
            .screenBackground()
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Clear", action: viewModel.clearFilters)
                        .disabled(viewModel.filter.isEmpty)
                        .tint(Palette.accentBlueBright)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .tint(Palette.accentBlueBright)
                }
            }
        }
    }

    private func facet<Value: Hashable>(
        _ title: String,
        values: [(Value, String)],
        toggle: @escaping (Value) -> Void,
        isSelected: @escaping (Value) -> Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(title)
            LazyVGrid(columns: columns, alignment: .leading, spacing: Spacing.sm) {
                ForEach(values, id: \.0) { value, label in
                    Button { toggle(value) } label: {
                        Chip(label, style: isSelected(value) ? .filledBlue : .ghost)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected(value) ? [.isSelected] : [])
                }
            }
        }
    }

    private func toggle<Value: Hashable>(_ set: inout Set<Value>, _ value: Value) {
        if set.contains(value) {
            set.remove(value)
        } else {
            set.insert(value)
        }
    }
}
