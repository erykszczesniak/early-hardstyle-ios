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

/// The app's root scene: a three-tab shell (Library · DJs · Saved) with a
/// persistent mini-player docked above the tab bar and the full player as a
/// cover. Playback is app-level (`PlaybackController`), shared via the
/// environment so any screen can start it.
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
    @State private var playback: PlaybackController

    public init(catalog: CatalogService, favourites: FavouritesService, analytics: any Analytics) {
        self.catalog = catalog
        self.favourites = favourites
        self.analytics = analytics
        _playback = State(initialValue: PlaybackController(
            analytics: analytics,
            favourites: favourites,
            makeEngine: { WebKitYouTubePlayer() }
        ))
    }

    public var body: some View {
        @Bindable var playback = playback

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
        .environment(playback)
        .safeAreaInset(edge: .bottom, spacing: 0) { miniPlayer }
        .fullScreenCover(isPresented: $playback.isExpanded) {
            PlayerView(controller: playback)
        }
    }

    @ViewBuilder
    private var miniPlayer: some View {
        if let nowPlaying = playback.nowPlaying, !playback.isExpanded {
            MiniPlayer(
                model: MiniPlayerModel(
                    title: nowPlaying.title,
                    subtitle: nowPlaying.subtitle,
                    thumbnailURL: nowPlaying.artworkURL,
                    isPlaying: playback.isPlaying,
                    isSaved: playback.currentIsSaved
                ),
                onPlayPause: { playback.togglePlayPause() },
                onToggleSave: { Task { await playback.toggleSaveCurrent() } },
                onOpen: { playback.expand() }
            )
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.xs)
        }
    }
}
