import SwiftUI

/// Set artwork loaded from a (YouTube-derived) URL, with a branded placeholder
/// while loading or when absent. Never ships copied artwork.
public struct Artwork: View {
    private let url: URL?
    private let cornerRadius: CGFloat

    public init(url: URL?, cornerRadius: CGFloat = Radius.thumbnail) {
        self.url = url
        self.cornerRadius = cornerRadius
    }

    public var body: some View {
        // `Color.clear` adopts exactly the size the call site proposes; the
        // image renders as an overlay and is clipped to those bounds. (Clipping
        // the AsyncImage directly ran before the outer frame, so a
        // scaledToFill image could blow past its slot — the DJ-detail row bug.)
        Color.clear
            .overlay {
                AsyncImage(url: url, transaction: Transaction(animation: .easeOut(duration: 0.25))) { phase in
                    switch phase {
                    case let .success(image):
                        image.resizable().scaledToFill()
                    case .failure:
                        placeholder(icon: "wifi.slash")
                    case .empty:
                        placeholder(icon: "music.note")
                    @unknown default:
                        placeholder(icon: "music.note")
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Palette.strokeSubtle, lineWidth: 1)
            )
    }

    private func placeholder(icon: String) -> some View {
        ZStack {
            Palette.elevated2
            Image(systemName: icon)
                .font(.system(size: 22, weight: .light))
                .foregroundStyle(Palette.textTertiary)
        }
    }
}
