import AVFoundation
import Foundation

// swiftformat:disable redundantSelf

/// The `PlaybackEngine` for licensed `.audio` sources, backed by `AVPlayer`.
/// Unlike the YouTube embed, native audio keeps playing in the background and
/// on the lock screen (the `audio` background mode + playback session are
/// already in place).
@MainActor
public final class AVPlayerAudioEngine: PlaybackEngine {
    public var onEvent: ((PlaybackEvent) -> Void)?

    private let player = AVPlayer()
    private var pendingStart: Int?
    private var duration: Double = 0
    private var statusObservation: NSKeyValueObservation?
    private var timeControlObservation: NSKeyValueObservation?
    /// Observer tokens that must be released on deinit; boxed so the
    /// nonisolated deinit can reach them under Swift 6 isolation rules.
    private let cleanup: CleanupBox

    private final class CleanupBox: @unchecked Sendable {
        private let lock = NSLock()
        private let player: AVPlayer
        private var timeToken: Any?
        private var endToken: NSObjectProtocol?

        init(player: AVPlayer) {
            self.player = player
        }

        func setTimeToken(_ token: Any) {
            lock.withLock { timeToken = token }
        }

        func replaceEndToken(_ token: NSObjectProtocol?) {
            lock.withLock {
                if let old = endToken {
                    NotificationCenter.default.removeObserver(old)
                }
                endToken = token
            }
        }

        func cancel() {
            lock.withLock {
                if let timeToken {
                    player.removeTimeObserver(timeToken)
                    self.timeToken = nil
                }
                if let endToken {
                    NotificationCenter.default.removeObserver(endToken)
                    self.endToken = nil
                }
            }
        }
    }

    public init() {
        cleanup = CleanupBox(player: player)
        let timeToken = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            MainActor.assumeIsolated {
                guard let self, self.duration > 0 else { return }
                self.onEvent?(.progress(time: time.seconds, duration: self.duration))
            }
        }
        cleanup.setTimeToken(timeToken)

        timeControlObservation = player.observe(\.timeControlStatus, options: [.new]) { [weak self] player, _ in
            let status = player.timeControlStatus
            Task { @MainActor [weak self] in
                switch status {
                case .playing:
                    self?.onEvent?(.playing)
                case .waitingToPlayAtSpecifiedRate:
                    self?.onEvent?(.buffering)
                case .paused:
                    // Initial pre-ready pauses are noise; only report a pause
                    // once something has actually loaded.
                    if let self, self.duration > 0 {
                        self.onEvent?(.paused)
                    }
                @unknown default:
                    break
                }
            }
        }
    }

    deinit {
        cleanup.cancel()
    }

    public func load(_ source: PlaybackSource, startAt seconds: Int?) {
        guard case let .audio(url) = source else {
            onEvent?(.failed(L10n.Player.errorGeneric))
            return
        }
        duration = 0
        pendingStart = seconds

        let item = AVPlayerItem(url: url)
        statusObservation = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            let status = item.status
            let itemDuration = item.duration.seconds
            Task { @MainActor [weak self] in
                self?.handleStatus(status, duration: itemDuration)
            }
        }
        cleanup.replaceEndToken(NotificationCenter.default.addObserver(
            forName: AVPlayerItem.didPlayToEndTimeNotification,
            object: item,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.onEvent?(.ended)
            }
        })
        player.replaceCurrentItem(with: item)
    }

    public func play() {
        player.play()
    }

    public func pause() {
        player.pause()
    }

    public func seek(toFraction fraction: Double) {
        guard duration > 0 else { return }
        let clamped = min(max(fraction, 0), 1)
        player.seek(to: CMTime(seconds: clamped * duration, preferredTimescale: 600))
    }

    private func handleStatus(_ status: AVPlayerItem.Status, duration itemDuration: Double) {
        switch status {
        case .readyToPlay:
            duration = itemDuration.isFinite ? itemDuration : 0
            if let start = pendingStart, start > 0 {
                pendingStart = nil
                player.seek(to: CMTime(seconds: Double(start), preferredTimescale: 600))
            }
            onEvent?(.ready)
        case .failed:
            onEvent?(.failed(L10n.Player.errorGeneric))
        default:
            break
        }
    }
}
