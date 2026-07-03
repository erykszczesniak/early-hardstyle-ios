import Core
import DesignSystem
import Services
import SwiftUI

/// Root namespace for the Features module: each screen ships as a `View` +
/// `ViewModel` pair (MVVM). ViewModels receive their services via initialiser
/// injection from the app's composition root — no singletons.
public enum Features {
    /// Human-readable module identifier, surfaced in the debug styleguide.
    public static let moduleName = "Features"
}

/// The app's root scene: a three-tab shell (Library · DJs · Saved) matching the
/// navigation defined in `DESIGN.md`. Services arrive from the composition root
/// and are handed to each screen's ViewModel.
public struct AppRootView: View {
    private enum Tab: Hashable {
        case library
        case djs
        case saved
    }

    private let catalog: CatalogService
    private let favourites: FavouritesService
    private let analytics: any Analytics

    @State private var selection: Tab = .library

    public init(catalog: CatalogService, favourites: FavouritesService, analytics: any Analytics) {
        self.catalog = catalog
        self.favourites = favourites
        self.analytics = analytics
    }

    public var body: some View {
        TabView(selection: $selection) {
            LibraryView(
                viewModel: LibraryViewModel(catalog: catalog, favourites: favourites, analytics: analytics)
            )
            .tag(Tab.library)
            .tabItem { Label("Library", systemImage: "square.grid.2x2") }

            DJsView(
                viewModel: DJsViewModel(catalog: catalog, favourites: favourites, analytics: analytics)
            )
            .tag(Tab.djs)
            .tabItem { Label("DJs", systemImage: "person.2") }

            SavedView(
                viewModel: SavedViewModel(catalog: catalog, favourites: favourites, analytics: analytics),
                onBrowseLibrary: { selection = .library }
            )
            .tag(Tab.saved)
            .tabItem { Label("Saved", systemImage: "heart") }
        }
    }
}
