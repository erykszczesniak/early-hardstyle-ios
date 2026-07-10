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
        case tracks
        case saved
    }

    private let catalog: CatalogService
    private let playbackProgress: PlaybackProgressStoring
    private let recentSearches: RecentSearchesStoring
    private let analytics: any Analytics

    @Environment(\.scenePhase) private var scenePhase
    @State private var selection: Tab = .library
    @State private var playback: PlaybackController
    /// The single observable source of truth for saved sets, shared by every
    /// screen and the mini-player.
    @State private var favourites: FavouritesStore

    public init(
        catalog: CatalogService,
        favourites: FavouritesService,
        playbackProgress: PlaybackProgressStoring,
        recentSearches: RecentSearchesStoring,
        analytics: any Analytics
    ) {
        self.catalog = catalog
        self.playbackProgress = playbackProgress
        self.recentSearches = recentSearches
        self.analytics = analytics
        _favourites = State(initialValue: FavouritesStore(service: favourites))
        _playback = State(initialValue: PlaybackController(
            analytics: analytics,
            progress: playbackProgress,
            makeEngine: { source in
                switch source {
                case .youtube: OfficialYouTubePlayer()
                case .audio: AVPlayerAudioEngine()
                }
            }
        ))
    }

    public var body: some View {
        ZStack {
            TabView(selection: $selection) {
                LibraryView(
                    viewModel: LibraryViewModel(
                        catalog: catalog,
                        favourites: favourites,
                        progress: playbackProgress,
                        recents: recentSearches,
                        analytics: analytics
                    )
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

                TracksView(
                    viewModel: TracksViewModel(catalog: catalog, favourites: favourites, analytics: analytics)
                )
                .safeAreaInset(edge: .bottom, spacing: 0) { miniPlayer }
                .tag(Tab.tracks)
                .tabItem { Label(L10n.Tab.tracks, systemImage: "metronome") }

                SavedView(
                    viewModel: SavedViewModel(catalog: catalog, favourites: favourites, analytics: analytics),
                    onBrowseLibrary: { selection = .library }
                )
                .safeAreaInset(edge: .bottom, spacing: 0) { miniPlayer }
                .tag(Tab.saved)
                .tabItem { Label(L10n.Tab.saved, systemImage: "heart") }
            }
            .modifier(MiniPlayerAccessory(
                isEnabled: playback.hasCurrent && !playback.isExpanded,
                content: { accessoryMiniPlayer }
            ))

            playerOverlay
        }
        .environment(playback)
        .task {
            WebKitPrewarm.run()
            await favourites.load()
        }
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
        .onOpenURL { url in
            guard let link = DeepLink.parse(url) else { return }
            Task { await handle(link) }
        }
    }

    /// Resolves a deep link against the catalogue and starts playback (the set
    /// plus its related queue, same as tapping PLAY in Set Detail).
    private func handle(_ link: DeepLink) async {
        guard let loaded = try? await catalog.loadCatalog() else { return }
        let target: HardstyleSet? = switch link {
        case let .play(setID):
            loaded.sets.first { $0.id == setID }
        case .playLatest:
            loaded.sets.max { $0.year < $1.year }
        }
        guard let target else { return }
        let queue = ([target] + SetDetailViewModel.related(to: target, in: loaded))
            .map { SetPresenter.nowPlaying(for: $0, in: loaded) }
        playback.play(queue)
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
            if let seed = ProcessInfo.processInfo.environment[LaunchEnvironment.seedProgress] {
                for triple in seed.split(separator: ",") {
                    let parts = triple.split(separator: ":").compactMap { Int($0) == nil ? nil : Int($0) }
                    let id = triple.split(separator: ":").first.map(String.init) ?? ""
                    if parts.count >= 2, !id.isEmpty {
                        playbackProgress.save(seconds: parts[0], duration: parts[1], for: id)
                    }
                }
            }
            let demoRequested = ProcessInfo.processInfo.environment[LaunchEnvironment.probeDemoAudio] != nil
            if demoRequested, let demo = Bundle.module.url(forResource: "DemoLoop", withExtension: "m4a") {
                playback.play([NowPlaying(
                    setID: "demo-loop",
                    title: "EARLYHS — Demo Loop",
                    subtitle: "150 BPM · native audio",
                    artworkURL: nil,
                    source: .audio(url: demo)
                )])
                return
            }
            guard let raw = ProcessInfo.processInfo.environment[LaunchEnvironment.probeVideoID],
                  !raw.isEmpty else { return }
            let items = raw.split(separator: ",").map(String.init).map { id in
                NowPlaying(
                    setID: "probe-\(id)",
                    title: id,
                    subtitle: "probe",
                    artworkURL: nil,
                    source: .youtube(id: id)
                )
            }
            playback.play(items)
        #endif
    }

    /// Legacy dock (iOS 17–25): the mini-player rides a `safeAreaInset` above
    /// the tab bar. On iOS 26 the floating Liquid Glass tab bar overlaps that
    /// inset — taps on play/pause fell through and switched tabs — so there the
    /// mini-player mounts as a `tabViewBottomAccessory` instead (see
    /// `accessoryMiniPlayer`) and this renders nothing.
    @ViewBuilder
    private var miniPlayer: some View {
        if #unavailable(iOS 26.0) {
            if let nowPlaying = playback.nowPlaying, !playback.isExpanded {
                miniPlayerContent(for: nowPlaying, context: .docked)
                    .padding(.horizontal, Spacing.md)
                    .padding(.bottom, Spacing.xs)
            }
        }
    }

    /// iOS 26 mount point: the system accessory slot above the floating tab
    /// bar, which supplies its own Liquid Glass and keeps taps to itself.
    /// Mounted with `isEnabled: false` while nothing plays (or the full player
    /// covers the screen), so no empty glass capsule ever shows — the accessory
    /// appears only once a track actually starts.
    @ViewBuilder
    private var accessoryMiniPlayer: some View {
        if let nowPlaying = playback.nowPlaying {
            miniPlayerContent(for: nowPlaying, context: .accessory)
        }
    }

    private func miniPlayerContent(for nowPlaying: NowPlaying, context: MiniPlayer.Context) -> some View {
        MiniPlayer(
            model: MiniPlayerModel(
                title: nowPlaying.title,
                subtitle: nowPlaying.subtitle,
                thumbnailURL: nowPlaying.artworkURL,
                isPlaying: playback.isPlaying,
                isSaved: favourites.isFavourite(nowPlaying.setID)
            ),
            context: context,
            onPlayPause: { playback.togglePlayPause() },
            onToggleSave: { Task { await favourites.toggle(nowPlaying.setID) } },
            onOpen: { playback.expand() }
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(A11yID.miniPlayer)
    }
}

/// Mounts `content` as a `tabViewBottomAccessory` on iOS 26+; a no-op before
/// (the legacy `safeAreaInset` dock handles those systems). `isEnabled` fully
/// removes the accessory — the system draws its glass capsule even for empty
/// content, so a boolean gate is the only way to hide it without rebuilding
/// the `TabView` (which would reset per-tab navigation state).
private struct MiniPlayerAccessory<Accessory: View>: ViewModifier {
    let isEnabled: Bool
    @ViewBuilder let content: () -> Accessory

    func body(content base: Content) -> some View {
        if #available(iOS 26.1, *) {
            base.tabViewBottomAccessory(isEnabled: isEnabled, content: content)
        } else if #available(iOS 26.0, *) {
            // 26.0 has no `isEnabled` — the empty capsule can show while idle
            // there, a cosmetic quirk fixed by the first point release.
            base.tabViewBottomAccessory(content: content)
        } else {
            base
        }
    }
}
