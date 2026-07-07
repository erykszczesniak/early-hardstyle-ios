import SwiftUI

/// Set artwork loaded from a (YouTube-derived) URL, with a branded placeholder
/// while loading or when absent. Never ships copied artwork.
///
/// Loads through `URLSession` directly rather than `AsyncImage`: `AsyncImage`
/// lands in `.failure` whenever a request is cancelled mid-flight (tab switch,
/// fast scroll) and never retries, leaving a permanent broken-image icon. Here
/// a transient failure retries with backoff, every reappearance retries again,
/// and the shared `URLCache` serves repeats instantly — so the real thumbnail
/// shows wherever it possibly can, and the only placeholder is the neutral one.
public struct Artwork: View {
    private let url: URL?
    private let cornerRadius: CGFloat

    @State private var image: Image?
    /// The URL `image` was decoded from, so a track/url change (e.g. the
    /// persistent mini-player switching sets) drops the stale artwork.
    @State private var loadedURL: URL?

    public init(url: URL?, cornerRadius: CGFloat = Radius.thumbnail) {
        self.url = url
        self.cornerRadius = cornerRadius
    }

    public var body: some View {
        // `Color.clear` adopts exactly the size the call site proposes; the
        // image renders as an overlay and is clipped to those bounds. (Clipping
        // the image directly ran before the outer frame, so a scaledToFill
        // image could blow past its slot — the DJ-detail row bug.)
        Color.clear
            .overlay {
                // Show the loaded image only when it belongs to the CURRENT url.
                // `Artwork` keeps a stable identity across url changes (e.g. the
                // persistent mini-player swapping sets), so without this guard
                // the previous track's cover would flash for one frame before
                // `.task` reloads — the image state outlives the url.
                if let image, loadedURL == url {
                    image.resizable().scaledToFill()
                } else {
                    placeholder
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Palette.strokeSubtle, lineWidth: 1)
            )
            .task(id: url) { await load() }
    }

    private func load() async {
        guard let url else { return }
        if image != nil, loadedURL == url { return } // already have this url's art
        for attempt in 1 ... 3 {
            if Task.isCancelled { return }
            let data = try? await URLSession.shared.data(from: url).0
            if let data, let loaded = UIImage(data: data) {
                withAnimation(.easeOut(duration: 0.25)) {
                    image = Image(uiImage: loaded)
                    loadedURL = url
                }
                return
            }
            // Transient failure — back off briefly, then try again.
            try? await Task.sleep(for: .milliseconds(400 * attempt))
        }
    }

    private var placeholder: some View {
        ZStack {
            Palette.elevated2
            Image(systemName: "music.note")
                .font(.system(size: 22, weight: .light))
                .foregroundStyle(Palette.textTertiary)
        }
    }
}
