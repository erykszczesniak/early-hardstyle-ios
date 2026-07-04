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
    private let analytics: any Analytics

    @State private var selection: Tab = .library
    @State private var playback: PlaybackController
    /// The single observable source of truth for saved sets, shared by every
    /// screen and the mini-player.
    @State private var favourites: FavouritesStore

    public init(catalog: CatalogService, favourites: FavouritesService, analytics: any Analytics) {
        self.catalog = catalog
        self.analytics = analytics
        _favourites = State(initialValue: FavouritesStore(service: favourites))
        _playback = State(initialValue: PlaybackController(
            analytics: analytics,
            makeEngine: { OfficialYouTubePlayer() }
        ))
    }

    public var body: some View {
        @Bindable var playback = playback

        TabView(selection: $selection) {
            LibraryView(
                viewModel: LibraryViewModel(catalog: catalog, favourites: favourites, analytics: analytics)
            )
            .tag(Tab.library)
            .tabItem { Label(L10n.Tab.library, systemImage: "square.grid.2x2") }

            DJsView(
                viewModel: DJsViewModel(catalog: catalog, favourites: favourites, analytics: analytics)
            )
            .tag(Tab.djs)
            .tabItem { Label(L10n.Tab.djs, systemImage: "person.2") }

            SavedView(
                viewModel: SavedViewModel(catalog: catalog, favourites: favourites, analytics: analytics),
                onBrowseLibrary: { selection = .library }
            )
            .tag(Tab.saved)
            .tabItem { Label(L10n.Tab.saved, systemImage: "heart") }
        }
        .environment(playback)
        .safeAreaInset(edge: .bottom, spacing: 0) { miniPlayer }
        .fullScreenCover(isPresented: $playback.isExpanded) {
            PlayerView(controller: playback)
        }
        .task { await favourites.load() }
        .onAppear(perform: startPlaybackProbeIfRequested)
    }

    /// DEBUG-only test seam: when `PROBE_VIDEO_ID` is set in the launch
    /// environment, launch straight into the player for that video so UI tests
    /// can verify real playback end-to-end. No effect in release builds.
    private func startPlaybackProbeIfRequested() {
        #if DEBUG
            guard let id = ProcessInfo.processInfo.environment["PROBE_VIDEO_ID"], !id.isEmpty else { return }
            playback.play([
                NowPlaying(setID: "probe", title: id, subtitle: "probe", artworkURL: nil, youtubeID: id)
            ])
        #endif
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
                    isSaved: favourites.isFavourite(nowPlaying.setID)
                ),
                onPlayPause: { playback.togglePlayPause() },
                onToggleSave: { Task { await favourites.toggle(nowPlaying.setID) } },
                onOpen: { playback.expand() }
            )
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.xs)
        }
    }
}
