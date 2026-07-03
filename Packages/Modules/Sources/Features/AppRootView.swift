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
/// and are handed to each screen's ViewModel. DJs and Saved land in their own
/// feature PRs.
public struct AppRootView: View {
    private let catalog: CatalogService
    private let favourites: FavouritesService
    private let analytics: any Analytics

    public init(catalog: CatalogService, favourites: FavouritesService, analytics: any Analytics) {
        self.catalog = catalog
        self.favourites = favourites
        self.analytics = analytics
    }

    public var body: some View {
        TabView {
            LibraryView(
                viewModel: LibraryViewModel(catalog: catalog, favourites: favourites, analytics: analytics)
            )
            .tabItem { Label("Library", systemImage: "square.grid.2x2") }

            placeholder(title: "DJs", systemImage: "person.2")
                .tabItem { Label("DJs", systemImage: "person.2") }

            placeholder(title: "Saved", systemImage: "heart")
                .tabItem { Label("Saved", systemImage: "heart") }
        }
    }

    private func placeholder(title: String, systemImage: String) -> some View {
        NavigationStack {
            EmptyState(
                systemImage: systemImage,
                title: title,
                message: "Coming soon."
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .screenBackground()
            .navigationTitle(title)
        }
    }
}
