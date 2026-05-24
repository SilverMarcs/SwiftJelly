#if !os(macOS)
import AVFoundation
import AVKit
import JellyfinAPI

extension MediaPlaybackViewModel {
    func setNowPlayingMetadata(for item: BaseItemDto, on playerItem: AVPlayerItem) async {
        var metadata: [AVMetadataItem] = []

        metadata.append(makeMetadataItem(.commonIdentifierTitle, value: item.nowPlayingTitle))
        if let subtitle = item.nowPlayingSubtitle {
            metadata.append(makeMetadataItem(.iTunesMetadataTrackSubTitle, value: subtitle))
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
        name ?? seriesName ?? "Unknown"
    }

    var nowPlayingSubtitle: String? {
        if type == .movie {
            return productionYear.map { String($0) }
        }
        let show = seriesName
        let episodeTag = seasonEpisodeString
        switch (show, episodeTag) {
        case let (show?, episodeTag?): return "\(show) • \(episodeTag)"
        case let (show?, nil): return show
        case let (nil, episodeTag?): return episodeTag
        default: return nil
        }
    }
}
#endif
