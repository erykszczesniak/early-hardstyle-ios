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

    @Environment(\.scenePhase) private var scenePhase
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
        ZStack {
            TabView(selection: $selection) {
                LibraryView(
                    viewModel: LibraryViewModel(catalog: catalog, favourites: favourites, analytics: analytics)
                )
                .safeAreaInset(edge: .bottom, spacing: 0) { miniPlayer }
                .tag(Tab.library)
                .tabItem { Label(L10n.Tab.library, systemImage: "square.grid.2x2") }

                DJsView(
                    viewModel: DJsViewModel(catalog: catalog, favourites: favourites, analytics: analytics)
                )
                .safeAreaInset(edge: .bottom, spacing: 0) { miniPlayer }
                .tag(Tab.djs)
                .tabItem { Label(L10n.Tab.djs, systemImage: "person.2") }

                SavedView(
                    viewModel: SavedViewModel(catalog: catalog, favourites: favourites, analytics: analytics),
                    onBrowseLibrary: { selection = .library }
                )
                .safeAreaInset(edge: .bottom, spacing: 0) { miniPlayer }
                .tag(Tab.saved)
                .tabItem { Label(L10n.Tab.saved, systemImage: "heart") }
            }

            playerOverlay
        }
        .environment(playback)
        .task { await favourites.load() }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .background:
                playback.appDidEnterBackground()
            case .active:
                playback.appDidBecomeActive()
            default:
                break
            }
        }
        .onAppear(perform: startPlaybackProbeIfRequested)
    }

    /// The full player as a persistent overlay (not a presented cover): while a
    /// track is loaded it stays mounted even when collapsed, so the engine's
    /// video surface never leaves the view hierarchy and audio keeps playing
    /// behind the mini-player.
    @ViewBuilder
    private var playerOverlay: some View {
        if playback.hasCurrent {
            PlayerView(controller: playback)
                .opacity(playback.isExpanded ? 1 : 0)
                .offset(y: playback.isExpanded ? 0 : 56)
                .allowsHitTesting(playback.isExpanded)
                .accessibilityHidden(!playback.isExpanded)
                .animation(.easeInOut(duration: 0.25), value: playback.isExpanded)
                .zIndex(1)
        }
    }

    /// DEBUG-only test seam: when `PROBE_VIDEO_ID` is set in the launch
    /// environment (a comma-separated list), launch straight into the player
    /// with those videos queued so UI tests can verify real playback — and real
    /// track switching — end-to-end. No effect in release builds.
    private func startPlaybackProbeIfRequested() {
        #if DEBUG
            guard let raw = ProcessInfo.processInfo.environment["PROBE_VIDEO_ID"], !raw.isEmpty else { return }
            let items = raw.split(separator: ",").map(String.init).map { id in
                NowPlaying(setID: "probe-\(id)", title: id, subtitle: "probe", artworkURL: nil, youtubeID: id)
            }
            playback.play(items)
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
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("mini-player")
        }
    }
}
