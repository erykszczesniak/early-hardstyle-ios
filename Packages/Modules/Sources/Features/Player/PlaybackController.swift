import Core
import Foundation
import Services

/// One queued item. Identified by its set id (a set appears at most once).
public struct QueueItem: Identifiable, Equatable, Sendable {
    public let nowPlaying: NowPlaying
    public var id: String {
        nowPlaying.setID
    }

    public init(_ nowPlaying: NowPlaying) {
        self.nowPlaying = nowPlaying
    }
}

/// App-level playback: owns the queue and the current player, so the mini-player
/// persists across tabs and the queue drives autoplay. Injected once from the
/// composition root and shared via the SwiftUI environment.
@MainActor
@Observable
public final class PlaybackController {
    private let analytics: any Analytics
    private let makeEngine: @MainActor () -> YouTubePlayer
    /// The single playback engine, created lazily and **reused for every
    /// track**. One engine = one video surface, so switching tracks loads the
    /// new video into the surface that is already on screen. (Creating an
    /// engine per track left the new engine's web view outside the view
    /// hierarchy — the UI kept showing, and hearing, the old one.)
    private var engine: YouTubePlayer?

    public private(set) var current: PlayerViewModel?
    public private(set) var queue: [QueueItem] = []
    public private(set) var index: Int = 0
    public var autoplayNext = true
    public var isExpanded = false

    public init(
        analytics: any Analytics,
        makeEngine: @escaping @MainActor () -> YouTubePlayer
    ) {
        self.analytics = analytics
        self.makeEngine = makeEngine
    }

    // MARK: Derived

    public var hasCurrent: Bool {
        current != nil
    }

    public var nowPlaying: NowPlaying? {
        current?.nowPlaying
    }

    public var isPlaying: Bool {
        current?.isPlaying ?? false
    }

    public var canGoNext: Bool {
        index + 1 < queue.count
    }

    public var canGoPrevious: Bool {
        index > 0
    }

    // MARK: Intent

    /// Replaces the queue with `items` and starts playback at `startAt`.
    public func play(_ items: [NowPlaying], startAt: Int = 0) {
        guard !items.isEmpty else { return }
        queue = items.map(QueueItem.init)
        index = min(max(startAt, 0), queue.count - 1)
        startCurrent()
        isExpanded = true
    }

    /// Inserts an item to play right after the current one.
    public func playNext(_ item: NowPlaying) {
        guard !queue.isEmpty else { return play([item]) }
        queue.removeAll { $0.id == item.setID }
        queue.insert(QueueItem(item), at: min(index + 1, queue.count))
    }

    /// Appends an item to the end of the queue.
    public func enqueue(_ item: NowPlaying) {
        guard !queue.isEmpty else { return play([item]) }
        guard !queue.contains(where: { $0.id == item.setID }) else { return }
        queue.append(QueueItem(item))
    }

    public func advance() {
        guard canGoNext else { return }
        index += 1
        startCurrent()
    }

    public func goPrevious() {
        guard canGoPrevious else { return }
        index -= 1
        startCurrent()
    }

    public func play(at position: Int) {
        guard queue.indices.contains(position) else { return }
        index = position
        startCurrent()
    }

    public func togglePlayPause() {
        current?.togglePlayPause()
    }

    public func expand() {
        guard hasCurrent else { return }
        isExpanded = true
    }

    /// Collapses the full player back to the mini-player. Playback continues —
    /// the player stays mounted (hidden), so the engine's surface never leaves
    /// the view hierarchy.
    public func collapse() {
        isExpanded = false
    }

    public func remove(_ item: QueueItem) {
        guard let position = queue.firstIndex(where: { $0.id == item.id }) else { return }
        // Removing the current item stops playback; removing an earlier item
        // keeps the current index pointing at the same track.
        queue.remove(at: position)
        if position == index {
            if queue.isEmpty {
                current = nil
                index = 0
            } else {
                index = min(index, queue.count - 1)
                startCurrent()
            }
        } else if position < index {
            index -= 1
        }
    }

    public func move(fromOffsets: IndexSet, toOffset: Int) {
        let currentID = queue.indices.contains(index) ? queue[index].id : nil
        queue.move(fromOffsets: fromOffsets, toOffset: toOffset)
        if let currentID, let newIndex = queue.firstIndex(where: { $0.id == currentID }) {
            index = newIndex
        }
    }

    // MARK: Internals

    private func startCurrent() {
        guard queue.indices.contains(index) else {
            current = nil
            return
        }
        let engine = engine ?? makeEngine()
        self.engine = engine
        let viewModel = PlayerViewModel(nowPlaying: queue[index].nowPlaying, player: engine, analytics: analytics)
        viewModel.onPlaybackEnded = { [weak self] in
            self?.handlePlaybackEnded()
        }
        current = viewModel
        viewModel.start()
    }

    private func handlePlaybackEnded() {
        if autoplayNext, canGoNext {
            advance()
        }
    }
}
