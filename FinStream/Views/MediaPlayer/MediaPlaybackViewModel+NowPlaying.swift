#if !os(macOS)
import AVFoundation
import AVKit
import JellyfinAPI

extension MediaPlaybackViewModel {
    func setNowPlayingMetadata(for item: BaseItemDto, on playerItem: AVPlayerItem) async {
        var metadata: [AVMetadataItem] = []

        metadata.append(makeMetadataItem(.commonIdentifierTitle, value: item.nowPlayingTitle))
        if let subtitle = item.nowPlayingSubtitle {
            metadata.append(makeMetadataItem(.commonIdentifierArtist, value: subtitle))
        }

        if let url = ImageURLProvider.imageURL(for: item, type: .primary),
           let (data, _) = try? await URLSession.shared.data(for: URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)) {
            metadata.append(makeMetadataItem(.commonIdentifierArtwork, value: data))
        }

        playerItem.externalMetadata = metadata
    }
}

private func makeMetadataItem(_ identifier: AVMetadataIdentifier, value: any Sendable) -> AVMetadataItem {
    let item = AVMutableMetadataItem()
    item.identifier = identifier
    item.value = value as? NSCopying & NSObjectProtocol
    item.extendedLanguageTag = "und"
    return item
}

private extension BaseItemDto {
    var nowPlayingTitle: String {
        type == .movie ? (name ?? "Unknown") : (seriesName ?? name ?? "Unknown")
    }

    var nowPlayingSubtitle: String? {
        guard type != .movie else { return nil }
        if let seasonEpisodeString {
            return "\(seasonEpisodeString) • \(name ?? "")"
        }
        return name
    }
}
#endif
